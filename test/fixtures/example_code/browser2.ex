defmodule Wallaby.Browser do
  @moduledoc ~S'''
  The Browser module is the entrypoint for interacting with a real browser.

  By default, action only work with elements that are visible to a real user.

  ## Actions

  Actions are used to interact with form elements. All actions work with the
  query interface:

  ```html
  <label for="first_name">
    First Name
  </label>
  <input id="user_first_name" type="text" name="first_name">
  ```

  ```
  fill_in(page, Query.text_field("First Name"), with: "Grace")
  fill_in(page, Query.text_field("first_name"), with: "Grace")
  fill_in(page, Query.text_field("user_first_name"), with: "Grace")
  ```

  These queries work with any of the available actions.

  ```
  fill_in(page, Query.text_field("First Name"), with: "Chris")
  clear(page, Query.text_field("user_email"))
  click(page, Query.radio_button("Radio Button 1"))
  click(page, Query.checkbox("Checkbox"))
  click(page, Query.checkbox("Checkbox"))
  click(page, Query.option("Option 1"))
  click(page, Query.button("Some Button"))
  attach_file(page, Query.file_field("Avatar"), path: "test/fixtures/avatar.jpg")
  ```

  Actions return their parent element so that they can be chained together:

  ```
  page
  |> find(Query.css(".signup-form"), fn(form) ->
    form
    |> fill_in(Query.text_field("Name"), with: "Grace Hopper")
    |> fill_in(Query.text_field("Email"), with: "grace@hopper.com")
    |> click(Query.button("Submit"))
  end)
  ```

  ## Scoping

  Finders provide scoping like so:

  ```
  session
  |> visit("/page.html")
  |> find(Query.css(".users"))
  |> find(Query.css(".user", count: 3))
  |> List.first
  |> find(Query.css(".user-name"))
  ```

  If a callback is passed to find then the scoping will only apply to the callback
  and the parent will be passed to the next action in the chain:

  ```
  page
  |> find(Query.css(".todo-form"), fn(form) ->
    form
    |> fill_in(Query.text_field("What needs doing?"), with: "Write Wallaby Documentation")
    |> click(Query.button("Save"))
  end)
  |> find(Query.css(".success-notification"), fn(notification) ->
    assert notification
    |> has_text?("Todo created successfully!")
  end)
  ```

  This allows you to create a test that is logically grouped together in a single pipeline.
  It also means that its easy to create re-usable helper functions without having to worry about
  chaining. You could re-write the above example like this:

  ```
  def create_todo(page, todo) do
    find(Query.css(".todo-form"), & fill_in_and_save_todo(&1, todo))
  end

  def fill_in_and_save_todo(form, todo) do
    form
    |> fill_in(Query.text_field("What needs doing?"), with: todo)
    |> click(Query.button("Save"))
  end

  def todo_was_created?(page) do
    find Query.css(page, ".success-notification"), fn(notification) ->
      assert notification
      |> has_text?("Todo created successfully!")
    end
  end

  assert page
  |> create_todo("Write Wallaby Documentation")
  |> todo_was_created?
  '''

  alias Wallaby.CookieError
  alias Wallaby.Element
  alias Wallaby.ExpectationNotMetError
  alias Wallaby.NoBaseUrlError
  alias Wallaby.Query
  alias Wallaby.Query.ErrorMessage
  alias Wallaby.Session
  alias Wallaby.StaleReferenceError

  @type t :: any()

  @typep session :: Session.t()
  @typep element :: Element.t()
  @opaque queryable ::
            Query.t()
            | Element.t()

  @type parent ::
          element
          | session
  @type opts :: Query.opts()

  @default_max_wait_time 3_000

  @doc '''
  Attempts to synchronize with the browser. This is most often used to
  execute queries repeatedly until it either exceeds the time limit or
  returns a success.

  ## Note

  It is possible that this function never halts. Whenever we experience a stale
  reference error we retry the query without checking to see if we've run over
  our time. In practice we should eventually be able to query the DOM in a stable
  state. However, if this error does continue to occur it will cause wallaby to
  loop forever (or until the test is killed by exunit).
  '''
  @type sync_result :: {:ok, any()} | {:error, any()}
  @spec retry((() -> sync_result), non_neg_integer()) :: sync_result()

  def retry(f, start_time \\ current_time()) do
    case f.() do
      {:ok, result} ->
        {:ok, result}

      {:error, :stale_reference} ->
        retry(f, start_time)

      {:error, :invalid_selector} ->
        {:error, :invalid_selector}

      {:error, e} ->
        if max_time_exceeded?(start_time) do
          {:error, e}
        else
          retry(f, start_time)
        end
    end
  end

  @doc '''
  Fills in an element identified by `query` with `value`.

  All inputs previously present in the input field will be overridden.

  ### Examples

      page
      |> fill_in(Query.text_field("name"), with: "Chris")
      |> fill_in(Query.css("#password_field"), with: "secret42")

  ### Note

  Currently, ChromeDriver only supports [BMP Unicode](http://www.unicode.org/roadmaps/bmp/) characters. Emojis are [SMP](https://www.unicode.org/roadmaps/smp/) characters and will be ignored by ChromeDriver.

  Using JavaScript is a known workaround for filling in fields with Emojis and other non-BMP characters.
  '''
  @spec fill_in(parent, Query.t(), with: String.t()) :: parent
  def fill_in(parent, query, with: value) do
    parent
    |> find(query, &Element.fill_in(&1, with: value))
  end

  # @doc '''
  # Clears an input field. Input elements are looked up by id, label text, or name.
  # The element can also be passed in directly.
  # '''
  @spec clear(parent, Query.t()) :: parent

  def clear(parent, query) do
    parent
    |> find(query, &Element.clear/1)
  end

  @doc '''
  Attaches a file to a file input. Input elements are looked up by id, label text,
  or name.

  When dealing with Selenium server (especially a remote instance), the file
  must be uploaded to Selenium via `send_keys` recognizing a local file,
  else attaching a file fails.
  '''
  @spec attach_file(parent, Query.t(), path: String.t()) :: parent
  def attach_file(parent, query, path: path) do
    case is_selenium?(parent) do
      true ->
        # local/remote selenium will only properly attach
        # & upload a local file with `send_keys`
        send_keys(parent, query, List.wrap(path))

      false ->
        # retain existing chrome compatibility
        set_value(parent, query, :filename.absname(path))
    end
  end

  @doc '''
  Takes a screenshot of the current window.
  Screenshots are saved to a "screenshots" directory in the same directory the
  tests are run in.

  Pass `[{:name, "some_name"}]` to specify the file name. Defaults to a timestamp.
  Pass `[{:log, true}]` to log the location of the screenshot to stdout. Defaults to false.
  '''
  @type take_screenshot_opt :: {:name, String.t()} | {:log, boolean}
  @spec take_screenshot(parent, [take_screenshot_opt]) :: parent

  def take_screenshot(%{driver: driver} = screenshotable, opts \\ []) do
    image_data =
      screenshotable
      |> driver.take_screenshot

    name =
      opts
      |> Keyword.get(:name, :erlang.system_time())
      |> to_string
      |> remove_illegal_characters

    path = path_for_screenshot(name)

    try do
      write_screenshot!(path, image_data)

      if opts[:log] do
        IO.puts("Screenshot taken, find it at #{build_file_url(path)}")
      end

      Map.update(screenshotable, :screenshots, [], &(&1 ++ [path]))
    rescue
      _ ->
        IO.puts("\nFailed to make a screenshot")

        screenshotable
    end
  end

  defp remove_illegal_characters(string), do: String.replace(string, ~r{<>:"/\\\?\*}, "")

  @doc '''
  Gets the window handle of the current window.

  The window is either an instance of a browser tab or another operating system window.
  Getting the current window handle makes it easy to return to the window in case you
  need to switch between them.

  ## Usage

  ```elixir
  feature "can open a new tab and switch back to the original tab", %{session: session} do
    handle =
      session
      |> visit("/home")
      |> window_handle()

    path =
      session
      # click a link that takes you to a new tab
      |> click(Query.link("External Page"))
      |> assert_text("Some text")
      |> focus_window(handle)
      |> current_path()

    assert "/home" == path
  end
  ```
  '''
  @spec window_handle(session :: Session.t()) :: String.t()
  def window_handle(%{driver: driver} = session) do
    {:ok, handle} = driver.window_handle(session)

    handle
  end

  @doc '''
  Gets the window handles of all available windows.

  The window is either an instance of a browser tab or another operating system window.

  ## Usage

  ```elixir
  feature "can open new tabs for external links", %{session: session} do
    handles =
      session
      |> visit("/home")
      |> click(Query.link("External Page"))
      |> click(Query.link("Another External Page"))
      |> window_handles()

    assert 3 == length(path)
  end
  ```
  '''
  @spec window_handles(session :: Session.t()) :: [String.t()]
  def window_handles(%{driver: driver} = session) do
    {:ok, handles} = driver.window_handles(session)

    handles
  end

  @doc '''
  Focuses the window identified by the given handle.

  The window is either an instance of a browser tab or another operating system window.

  ## Usage

  ```elixir
  feature "can switch between different tabs", %{session: session} do
    handle =
      session
      |> visit("/home")
      |> window_handle()

    path =
      session
      # click a link that takes you to a new tab
      |> click(Query.link("External Page"))
      |> assert_text("Some text")
      |> focus_window(handle)
      |> current_path()

    assert "/home" == path
  end
  ```
  '''
  @spec focus_window(session :: Session.t(), window_handle :: String.t()) :: parent
  def focus_window(%{driver: driver} = session, window_handle) do
    {:ok, _} = driver.focus_window(session, window_handle)

    session
  end

  @doc '''
  Closes the current window.

  The window is either an instance of a browser tab or another operating system window.

  ## Usage

  ```elixir
  feature "closing a window focuses the previously focused window", %{session: session} do
    original_handle =
      session
      |> visit("/home")
      |> window_handle()

    new_handle =
      session
      # click a link that takes you to a new tab
      |> click(Query.link("External Page"))
      |> close_window()
      |> window_handle()

    assert original_handle == new_handle
  end
  ```
  '''
  @spec close_window(session :: Session.t()) :: Session.t()
  def close_window(%{driver: driver} = session) do
    {:ok, _} = driver.close_window(session)

    session
  end

  @doc '''
  Gets the size of the current window.

  The window is either an instance of a browser tab or another operating system window.

  This is useful for debugging responsive designs where the layout changes as the window size changes. The default window size is 1280x800.

  ## Usage

  ```elixir
  feature "gets the size of the current window", %{session: session} do
    %{"width" => width, "height" => height} =
      session
      |> visit("/home")
      |> window_size()

    assert width == 1280
    assert height == 800
  end
  ```
  '''
  @spec window_size(session :: Session.t()) :: %{
          String.t() => pos_integer,
          String.t() => pos_integer
        }
  def window_size(%{driver: driver} = session) do
    {:ok, size} = driver.get_window_size(session)

    size
  end

  @doc '''
  Sets the size of the current window.

  The window is either an instance of a browser tab or another operating system window.

  ## Usage

  ```elixir
  feature "sets the size of the window to mobile dimensions", %{session: session} do
    %{"width" => width, "height" => height} =
      session
      |> visit("/home")
      |> resize_window(375, 667)
      |> window_size()

    assert width == 375
    assert height == 667
  end
  ```
  '''
  @spec resize_window(session :: Session.t(), width :: pos_integer(), height :: pos_integer()) ::
          Session.t()
  def resize_window(%{driver: driver} = session, width, height) do
    {:ok, _} = driver.set_window_size(session, width, height)

    session
  end

  @doc '''
  Maximizes the current window.

  The window is either an instance of a browser tab or another operating system window.

  For most browsers, this requires a graphical window manager to be running.

  ## Usage

  ```elixir
  feature "maximizes the window to the full size of the display", %{session: session} do
    %{"width" => width, "height" => height} =
      session
      |> visit("/home")
      |> maximize_window()
      |> window_size()

    assert width == 1920
    assert height == 1080
  end
  ```
  '''
  @spec maximize_window(session :: Session.t()) :: Session.t()
  def maximize_window(%{driver: driver} = session) do
    {:ok, _} = driver.maximize_window(session)

    session
  end

  @doc '''
  Gets the position of the current window.

  The window is either an instance of a browser tab or another operating system window.

  ## Usage

  ```elixir
  feature "gets the current display position of the window", %{session: session} do
    %{"x" => x, "y" => y} =
      session
      |> visit("/home")
      |> window_position()

    assert x == 200
    assert y == 200
  end
  ```
  '''
  @spec window_position(session :: Session.t()) :: %{
          String.t() => pos_integer,
          String.t() => pos_integer
        }
  def window_position(%{driver: driver} = session) do
    {:ok, position} = driver.get_window_position(session)

    position
  end

  @doc '''
  Sets the position of the current window.

  The window is either an instance of a browser tab or another operating system window.

  ## Usage

  ```elixir
  feature "gets the current display position of the window", %{session: session} do
    %{"x" => x, "y" => y} =
      session
      |> visit("/home")
      |> move_window(500, 500)
      |> window_position()

    assert x == 500
    assert y == 500
  end
  ```
  '''
  @spec move_window(session :: Session.t(), x :: pos_integer(), y :: pos_integer()) :: Session.t()
  def move_window(%{driver: driver} = session, x, y) do
    {:ok, _} = driver.set_window_position(session, x, y)

    session
  end

  @doc '''
  Changes the driver focus to the frame found by query.
  '''
  @spec focus_frame(parent, Query.t()) :: parent
  def focus_frame(%{driver: driver} = session, %Query{} = query) do
    session
    |> find(query, &driver.focus_frame(session, &1))
  end

  @doc '''
  Changes the driver focus to the parent frame.
  '''
  @spec focus_parent_frame(parent) :: parent

  def focus_parent_frame(%{driver: driver} = session) do
    {:ok, _} = driver.focus_parent_frame(session)
    session
  end

  @doc '''
  Changes the driver focus to the default (top level) frame.
  '''
  @spec focus_default_frame(parent) :: parent

  def focus_default_frame(%{driver: driver} = session) do
    {:ok, _} = driver.focus_frame(session, nil)
    session
  end

  @doc '''
  Gets the current url of the session
  '''
  @spec current_url(parent) :: String.t()

  def current_url(%Session{driver: driver} = session) do
    {:ok, url} = driver.current_url(session)
    url
  end

  @doc '''
  Gets the current path of the session
  '''
  @spec current_path(parent) :: String.t()

  def current_path(%Session{driver: driver} = session) do
    {:ok, path} = driver.current_path(session)
    path
  end

  @doc '''
  Gets the title for the current page
  '''
  @spec page_title(parent) :: String.t()

  def page_title(%Session{driver: driver} = session) do
    {:ok, title} = driver.page_title(session)
    title
  end

  @doc '''
  Executes JavaScript synchronously, taking as arguments the script to execute,
  an optional list of arguments available in the script via `arguments`, and an
  optional callback function with the result of script execution as a parameter.
  '''
  @spec execute_script(parent, String.t()) :: parent
  @spec execute_script(parent, String.t(), list) :: parent
  @spec execute_script(parent, String.t(), (binary() -> any())) :: parent
  @spec execute_script(parent, String.t(), list, (binary() -> any())) :: parent

  def execute_script(session, script) do
    execute_script(session, script, [])
  end

  def execute_script(session, script, arguments) when is_list(arguments) do
    execute_script(session, script, arguments, fn _ -> nil end)
  end

  def execute_script(session, script, callback) when is_function(callback) do
    execute_script(session, script, [], callback)
  end

  def execute_script(%{driver: driver} = parent, script, arguments, callback)
      when is_list(arguments) and is_function(callback) do
    {:ok, value} = driver.execute_script(parent, script, arguments)
    callback.(value)
    parent
  end

  @doc '''
  Executes asynchronous JavaScript, taking as arguments the script to execute,
  an optional list of arguments available in the script via `arguments`, and an
  optional callback function with the result of script execution as a parameter.
  '''
  @spec execute_script_async(parent, String.t()) :: parent
  @spec execute_script_async(parent, String.t(), list) :: parent
  @spec execute_script_async(parent, String.t(), (binary() -> any())) :: parent
  @spec execute_script_async(parent, String.t(), list, (binary() -> any())) :: parent

  def execute_script_async(session, script) do
    execute_script_async(session, script, [])
  end

  def execute_script_async(session, script, arguments) when is_list(arguments) do
    execute_script_async(session, script, arguments, fn _ -> nil end)
  end

  def execute_script_async(session, script, callback) when is_function(callback) do
    execute_script_async(session, script, [], callback)
  end

  def execute_script_async(%{driver: driver} = parent, script, arguments, callback)
      when is_list(arguments) and is_function(callback) do
    {:ok, value} = driver.execute_script_async(parent, script, arguments)
    callback.(value)
    parent
  end

  @doc '''
  Sends a list of key strokes to active element. If strings are included
  then they are sent as individual keys. Special keys should be provided as a
  list of atoms, which are automatically converted into the corresponding key
  codes.

  For a list of available key codes see `Wallaby.Helpers.KeyCodes`.

  ## Example

      iex> Wallaby.Session.send_keys(session, ["Example Text", :enter])
      iex> Wallaby.Session.send_keys(session, [:enter])
      iex> Wallaby.Session.send_keys(session, [:shift, :enter])

  ### Note

  Currently, ChromeDriver only supports [BMP Unicode](http://www.unicode.org/roadmaps/bmp/) characters. Emojis are [SMP](https://www.unicode.org/roadmaps/smp/) characters and will be ignored by ChromeDriver.

  Using JavaScript is a known workaround for filling in fields with Emojis and other non-BMP characters.
  '''
  @spec send_keys(parent, Query.t(), Element.keys_to_send()) :: parent
  @spec send_keys(parent, Element.keys_to_send()) :: parent

  def send_keys(parent, query, list) do
    find(parent, query, fn element ->
      element
      |> Element.send_keys(list)
    end)
  end

  def send_keys(%Element{} = element, keys) do
    Element.send_keys(element, keys)
  end

  def send_keys(parent, keys) when is_binary(keys) do
    send_keys(parent, [keys])
  end

  def send_keys(%{driver: driver} = parent, keys) when is_list(keys) do
    {:ok, _} = driver.send_keys(parent, keys)
    parent
  end

  @doc '''
  Retrieves the source of the current page.
  '''
  @spec page_source(parent) :: String.t()

  def page_source(%Session{driver: driver} = session) do
    {:ok, source} = driver.page_source(session)
    source
  end

  @doc '''
  Sets the value of an element. The allowed type for the value depends on the
  type of the element. The value may be:
  * a string of characters for a text element
  * :selected for a radio button, checkbox or select list option
  * :unselected for a checkbox
  '''
  @spec set_value(parent, Query.t(), Element.value()) :: parent

  def set_value(parent, query, :selected) do
    find(parent, query, fn element ->
      case Element.selected?(element) do
        true -> :ok
        false -> Element.click(element)
      end
    end)
  end

  def set_value(parent, query, :unselected) do
    find(parent, query, fn element ->
      case Element.selected?(element) do
        false -> :ok
        true -> Element.click(element)
      end
    end)
  end

  def set_value(parent, query, value) do
    find(parent, query, fn element ->
      element
      |> Element.set_value(value)
    end)
  end

  @doc '''
  Clicks the mouse on the element returned by the query or at the current mouse cursor position.
  '''
  @spec click(parent, :left | :middle | :right) :: parent
  @spec click(parent, Query.t()) :: parent
  def click(parent, button) when button in [:left, :middle, :right] do
    case parent.driver.click(parent, button) do
      {:ok, _} ->
        parent
    end
  end

  def click(parent, query) do
    parent
    |> find(query, &Element.click/1)
  end

  @doc '''
  Double-clicks left mouse button at the current mouse coordinates.
  '''
  @spec double_click(parent) :: parent
  def double_click(parent) do
    case parent.driver.double_click(parent) do
      {:ok, _} ->
        parent
    end
  end

  @doc '''
   Clicks and holds the given mouse button at the current mouse coordinates.
  '''
  @spec button_down(parent, atom) :: parent
  def button_down(parent, button \\ :left) when button in [:left, :middle, :right] do
    case parent.driver.button_down(parent, button) do
      {:ok, _} ->
        parent
    end
  end

  @doc '''
   Releases given previously held mouse button.
  '''
  @spec button_up(parent, atom) :: parent
  def button_up(parent, button \\ :left) when button in [:left, :middle, :right] do
    case parent.driver.button_up(parent, button) do
      {:ok, _} ->
        parent
    end
  end

  @doc '''
  Hovers over an element.
  '''
  @spec hover(parent, Query.t()) :: parent
  def hover(parent, query) do
    parent
    |> find(query, &Element.hover/1)
  end

  @doc '''
  Moves mouse by an offset relative to current cursor position.
  '''
  @spec move_mouse_by(parent, integer, integer) :: parent
  def move_mouse_by(parent, x_offset, y_offset) do
    case parent.driver.move_mouse_by(parent, x_offset, y_offset) do
      {:ok, _} ->
        parent
    end
  end

  @doc '''
  Touches the screen at the given position.
  '''
  @spec touch_down(parent, integer, integer) :: session

  def touch_down(parent, x, y) when is_integer(x) and is_integer(y) do
    case parent.driver.touch_down(parent, nil, x, y) do
      {:ok, _} ->
        parent
    end
  end

  @doc '''
  Touches and holds the element on its top-left corner plus an optional offset.
  '''
  @spec touch_down(parent, Query.t(), integer, integer) :: session

  def touch_down(parent, query, x_offset \\ 0, y_offset \\ 0) do
    parent
    |> find(query, &Element.touch_down(&1, x_offset, y_offset))
  end

  @doc '''
  Stops touching the screen.
  '''
  @spec touch_up(parent) :: parent

  def touch_up(parent) do
    case parent.driver.touch_up(parent) do
      {:ok, _} ->
        parent
    end
  end

  @doc '''
  Taps the element.
  '''
  @spec tap(parent, Query.t()) :: session

  def tap(parent, query) do
    parent
    |> find(query, &Element.tap/1)
  end

  @doc '''
  Moves the touch pointer (finger, stylus etc.) on the screen to the point determined by the given coordinates.
  '''
  @spec touch_move(parent, non_neg_integer, non_neg_integer) :: parent

  def touch_move(parent, x, y) do
    case parent.driver.touch_move(parent, x, y) do
      {:ok, _} ->
        parent
    end
  end

  @doc '''
  Scroll on the screen from the given element by the given offset using touch events.
  '''
  @spec touch_scroll(parent, Query.t(), integer, integer) :: parent

  def touch_scroll(parent, query, x, y) do
    parent
    |> find(query, &Element.touch_scroll(&1, x, y))
  end

  @doc '''
  Gets the Element's text value.

  If the element is not visible, the return value will be `""`.
  '''
  @spec text(parent) :: String.t()
  @spec text(parent, Query.t()) :: String.t()
  def text(parent, query) do
    parent
    |> find(query)
    |> Element.text()
  end

  def text(%Session{} = session) do
    session
    |> find(Query.css("body"))
    |> Element.text()
  end

  @doc '''
  Gets the value of the elements attribute.
  '''
  @spec attr(parent, Query.t(), String.t()) :: String.t() | nil
  def attr(parent, query, name) do
    parent
    |> find(query)
    |> Element.attr(name)
  end

  @doc '''
  Checks if the element has been selected. Alias for checked?(element)
  '''
  @spec selected?(parent, Query.t()) :: boolean()
  def selected?(parent, query) do
    parent
    |> find(query)
    |> Element.selected?()
  end

  @doc '''
  Checks if the element is visible on the page
  '''
  @spec visible?(parent, Query.t()) :: boolean()
  def visible?(parent, query) do
    parent
    |> has?(query)
  end

  @doc '''
  Finds a specific DOM element on the page based on a CSS selector. Blocks until
  it either finds the element or until the max time is reached. By default only
  1 element is expected to match the query. If more elements are present then a
  count can be specified. Use `:any` to allow any number of elements to be present.
  By default only elements that are visible on the page are returned.

  Selections can be scoped by providing a Element as the locator for the query.

  By default finders only work with elements that would be visible to a real
  user.
  '''
  @spec find(parent, Query.t(), (Element.t() -> any())) :: parent
  @spec find(parent, Query.t()) :: Element.t() | [Element.t()]
  @spec find(parent, String.t()) :: Element.t() | [Element.t()]
  def find(parent, %Query{} = query, callback) when is_function(callback) do
    results = find(parent, query)
    callback.(results)
    parent
  end

  def find(parent, %Query{} = query) do
    case execute_query(parent, query) do
      {:ok, query} ->
        query
        |> Query.result()

      {:error, {:not_found, result}} ->
        query = %Query{query | result: result}

        case validate_html(parent, query) do
          {:ok, _} ->
            raise Wallaby.QueryError, ErrorMessage.message(query, :not_found)

          {:error, html_error} ->
            raise Wallaby.QueryError, ErrorMessage.message(query, html_error)
        end

      {:error, e} ->
        raise Wallaby.QueryError, ErrorMessage.message(query, e)
    end
  end

  @doc '''
  Finds all of the DOM elements that match the CSS selector. If no elements are
  found then an empty list is immediately returned. This is equivalent to calling
  `find(session, css("element", count: nil, minimum: 0))`.
  '''
  @spec all(parent, Query.t()) :: [Element.t()]
  def all(parent, %Query{} = query) do
    find(
      parent,
      %Query{query | conditions: Keyword.merge(query.conditions, count: nil, minimum: 0)}
    )
  end

  @doc '''
  Validates that the query returns a result. This can be used to define other
  types of matchers.
  '''
  @spec has?(parent, Query.t()) :: boolean()
  def has?(parent, query) do
    case execute_query(parent, query) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  @doc '''
  Matches the Element's value with the provided value.
  '''
  @spec has_value?(parent, Query.t(), any()) :: boolean()
  @spec has_value?(Element.t(), any()) :: boolean()
  def has_value?(parent, query, value) do
    parent
    |> find(query)
    |> has_value?(value)
  end

  def has_value?(%Element{} = element, value) do
    result =
      retry(fn ->
        if Element.value(element) == value do
          {:ok, true}
        else
          {:error, false}
        end
      end)

    case result do
      {:ok, true} ->
        true

      {:error, false} ->
        false
    end
  end

  @doc '''
  Matches the parent's content with the provided text.

  Returns a boolean that indicates if the text was found.

  ## Examples

  ```
  session
  |> visit("/")
  |> has_text?("Login")
  ```

  Example providing query:

  ```
  session
  |> visit("/")
  |> has_text?(Query.css(".login-button"), "Login")
  ```
  '''
  @spec has_text?(parent, String.t()) :: boolean()
  @spec has_text?(parent, Query.t(), String.t()) :: boolean()
  def has_text?(parent, query, text) do
    parent
    |> find(query)
    |> has_text?(text)
  end

  def has_text?(%Session{} = session, text) when is_binary(text) do
    session
    |> find(Query.css("body"))
    |> has_text?(text)
  end

  def has_text?(parent, text) when is_binary(text) do
    result =
      retry(fn ->
        if Element.text(parent) =~ text do
          {:ok, true}
        else
          {:error, false}
        end
      end)

    case result do
      {:ok, true} ->
        true

      {:error, false} ->
        false
    end
  end

  @doc '''
  Matches the Element's content with the provided text and raises if not found.

  Returns the given `parent` if the assertion is correct so that it is easily
  pipeable.

  ## Examples

  ```
  session
  |> visit("/")
  |> assert_text("Login")
  ```

  Example providing query:

  ```
  session
  |> visit("/")
  |> assert_text(Query.css(".login-button"), "Login")
  ```
  '''
  @spec assert_text(parent, String.t()) :: parent
  @spec assert_text(parent, Query.t(), String.t()) :: parent
  def assert_text(parent, query, text) when is_binary(text) do
    parent
    |> find(query)
    |> assert_text(text)
  end

  def assert_text(parent, text) when is_binary(text) do
    if has_text?(parent, text) do
      parent
    else
      raise ExpectationNotMetError, "Text '#{text}' was not found."
    end
  end

  @doc '''
  Checks if `query` is present within `parent` and raises if not found.

  Returns the given `parent` if the assertion is correct so that it is easily
  pipeable.

  ## Examples

      session
      |> visit("/")
      |> assert_has(Query.css(".login-button"))
  '''

  defmacro assert_has(parent, query) do
    quote do
      parent = unquote(parent)
      query = unquote(query)

      case execute_query(parent, query) do
        {:ok, _query_result} ->
          parent

        error ->
          case error do
            {:error, {:not_found, results}} ->
              query = %Query{query | result: results}

              raise ExpectationNotMetError,
                    Query.ErrorMessage.message(query, :not_found)

            {:error, :invalid_selector} ->
              raise Wallaby.QueryError,
                    Query.ErrorMessage.message(query, :invalid_selector)

            _ ->
              raise Wallaby.ExpectationNotMetError,
                    "Wallaby has encountered an internal error: #{inspect(error)} with session: #{inspect(parent)}"
          end
      end
    end
  end

  @doc '''
  Checks if `query` is not present within `parent` and raises if it is found.

  Returns the given `parent` if the query is not found so that it is easily
  pipeable.

  ## Examples

      session
      |> visit("/")
      |> refute_has(Query.css(".secret-admin-content"))
  '''
  defmacro refute_has(parent, query) do
    quote do
      parent = unquote(parent)
      query = unquote(query)

      case execute_query(parent, query) do
        {:error, _not_found} ->
          parent

        {:ok, query} ->
          raise Wallaby.ExpectationNotMetError,
                Query.ErrorMessage.message(query, :found)
      end
    end
  end

  @doc '''
  Searches for CSS on the page.
  '''
  @spec has_css?(parent, Query.t(), String.t()) :: boolean()
  @spec has_css?(parent, String.t()) :: boolean()
  def has_css?(parent, query, css) when is_binary(css) do
    parent
    |> find(query)
    |> has?(Query.css(css, count: :any))
  end

  def has_css?(parent, css) when is_binary(css) do
    parent
    |> has?(Query.css(css, count: :any))
  end

  @doc '''
  Searches for CSS that should not be on the page
  '''
  @spec has_no_css?(parent, Query.t(), String.t()) :: boolean()
  @spec has_no_css?(parent, String.t()) :: boolean()
  def has_no_css?(parent, query, css) when is_binary(css) do
    parent
    |> find(query)
    |> has?(Query.css(css, count: 0))
  end

  def has_no_css?(parent, css) when is_binary(css) do
    parent
    |> has?(Query.css(css, count: 0))
  end

  @doc '''
  Changes the current page to the provided route.
  Relative paths are appended to the provided base_url.
  Absolute paths do not use the base_url.
  '''
  @spec visit(session, String.t()) :: session
  def visit(%Session{driver: driver} = session, path) do
    uri = URI.parse(path)

    cond do
      uri.host == nil && String.length(base_url()) == 0 ->
        raise NoBaseUrlError, path

      uri.host ->
        driver.visit(session, path)

      true ->
        driver.visit(session, request_url(path))
    end

    session
  end

  def cookies(%Session{driver: driver} = session) do
    {:ok, cookies_list} = driver.cookies(session)

    cookies_list
  end

  def set_cookie(%Session{driver: driver} = session, key, value) do
    if blank_page?(session) do
      raise CookieError
    end

    case driver.set_cookie(session, key, value) do
      {:ok, _list} ->
        session

      {:error, :invalid_cookie_domain} ->
        raise CookieError
    end
  end

  defp blank_page?(%Session{driver: driver} = session) do
    driver.blank_page?(session)
  end

  @doc '''
  Accepts one alert dialog, which must be triggered within the specified `fun`.
  Returns the message that was presented to the user. For example:

  ```
  message = accept_alert session, fn(s) ->
    click(s, Query.link("Trigger alert"))
  end
  ```
  '''
  def accept_alert(%Session{driver: driver} = session, fun) do
    driver.accept_alert(session, fun)
  end

  @doc '''
  Accepts one confirmation dialog, which must be triggered within the specified
  `fun`. Returns the message that was presented to the user. For example:

  ```
  message = accept_confirm session, fn(s) ->
    click(s, Query.link("Trigger confirm"))
  end
  ```
  '''
  def accept_confirm(%Session{driver: driver} = session, fun) do
    driver.accept_confirm(session, fun)
  end

  @doc '''
  Dismisses one confirmation dialog, which must be triggered within the
  specified `fun`. Returns the message that was presented to the user. For
  example:

  ```
  message = dismiss_confirm session, fn(s) ->
    click(s, Query.link("Trigger confirm"))
  end
  ```
  '''
  def dismiss_confirm(%Session{driver: driver} = session, fun) do
    driver.dismiss_confirm(session, fun)
  end

  @doc '''
  Accepts one prompt, which must be triggered within the specified `fun`. The
  `[with: value]` option allows to simulate user input for the prompt. If no
  value is provided, the default value that was passed to `window.prompt` will
  be used instead. Returns the message that was presented to the user. For
  example:

  ```
  message = accept_prompt session, fn(s) ->
    click(s, Query.link("Trigger prompt"))
  end
  ```

  Example providing user input:

  ```
  message = accept_prompt session, [with: "User input"], fn(s) ->
    click(s, Query.link("Trigger prompt"))
  end
  ```
  '''
  def accept_prompt(%Session{} = session, fun) do
    do_accept_prompt(session, nil, fun)
  end

  def accept_prompt(%Session{} = session, [with: input_value], fun) when is_binary(input_value) do
    do_accept_prompt(session, input_value, fun)
  end

  defp do_accept_prompt(%Session{driver: driver} = session, input_value, fun) do
    driver.accept_prompt(session, input_value, fun)
  end

  @doc '''
  Dismisses one prompt, which must be triggered within the specified `fun`.
  Returns the message that was presented to the user. For example:

  ```
  message = dismiss_prompt session, fn(s) ->
    click(s, Query.link("Trigger prompt"))
  end
  ```
  '''
  def dismiss_prompt(%Session{driver: driver} = session, fun) do
    driver.dismiss_prompt(session, fun)
  end

  defp validate_html(parent, %{html_validation: :button_type} = query) do
    buttons = all(parent, Query.css("button", text: query.selector))

    if Enum.count(buttons) == 1 && Enum.any?(buttons) do
      {:error, :button_with_bad_type}
    else
      {:ok, query}
    end
  end

  defp validate_html(parent, %{html_validation: :bad_label} = query) do
    label_query = Query.css("label", text: query.selector)
    labels = all(parent, label_query)

    if Enum.count(labels) == 1 do
      if Enum.any?(labels, &missing_for?(&1)) do
        {:error, :label_with_no_for}
      else
        label = List.first(labels)
        {:error, {:label_does_not_find_field, Element.attr(label, "for")}}
      end
    else
      {:ok, query}
    end
  end

  defp validate_html(_, query), do: {:ok, query}

  defp missing_for?(element) do
    Element.attr(element, "for") == nil
  end

  defp validate_visibility(query, elements) do
    case Query.visible?(query) do
      :any ->
        {:ok, elements}

      true ->
        {:ok, Enum.filter(elements, &Element.visible?(&1))}

      false ->
        {:ok, Enum.reject(elements, &Element.visible?(&1))}
    end
  end

  defp validate_selected(query, elements) do
    case Query.selected?(query) do
      :any ->
        {:ok, elements}

      true ->
        {:ok, Enum.filter(elements, &Element.selected?(&1))}

      false ->
        {:ok, Enum.reject(elements, &Element.selected?(&1))}
    end
  end

  defp validate_count(query, elements) do
    if Query.matches_count?(query, Enum.count(elements)) do
      {:ok, elements}
    else
      {:error, {:not_found, elements}}
    end
  end

  defp do_at(query, elements) do
    case {Query.at_number(query), length(elements)} do
      {:all, _} ->
        {:ok, elements}

      {n, count} when n >= 0 and n < count ->
        {:ok, [Enum.at(elements, n)]}

      {_, _} ->
        {:error, {:at_number, query}}
    end
  end

  defp validate_text(query, elements) do
    text = Query.inner_text(query)

    if text do
      {:ok, Enum.filter(elements, &matching_text?(&1, text))}
    else
      {:ok, elements}
    end
  end

  defp matching_text?(%Element{driver: driver} = element, text) do
    case driver.text(element) do
      {:ok, element_text} ->
        element_text =~ ~r/#{Regex.escape(text)}/

      {:error, _} ->
        false
    end
  end

  def execute_query(%{driver: driver} = parent, query) do
    retry(fn ->
      try do
        with {:ok, query} <- Query.validate(query),
             compiled_query <- Query.compile(query),
             {:ok, elements} <- driver.find_elements(parent, compiled_query),
             {:ok, elements} <- validate_visibility(query, elements),
             {:ok, elements} <- validate_text(query, elements),
             {:ok, elements} <- validate_selected(query, elements),
             {:ok, elements} <- validate_count(query, elements),
             {:ok, elements} <- do_at(query, elements) do
          {:ok, %Query{query | result: elements}}
        end
      rescue
        StaleReferenceError ->
          {:error, :stale_reference}
      end
    end)
  end

  defp max_time_exceeded?(start_time) do
    current_time() - start_time > max_wait_time()
  end

  defp current_time do
    :erlang.monotonic_time(:milli_seconds)
  end

  defp max_wait_time do
    Application.get_env(:wallaby, :max_wait_time, @default_max_wait_time)
  end

  defp request_url(path) do
    base_url = String.trim_trailing(base_url(), "/")
    path = String.trim_leading(path, "/")

    "#{base_url}/#{path}"
  end

  defp base_url do
    Application.get_env(:wallaby, :base_url) || ""
  end

  defp path_for_screenshot(name) do
    "#{screenshot_dir()}/#{name}.png"
  end

  defp write_screenshot!(path, image_data) do
    expanded_path = Path.expand(path)
    :ok = expanded_path |> Path.dirname() |> File.mkdir_p!()

    :ok = File.write!(expanded_path, image_data)

    :ok
  end

  defp screenshot_dir do
    Application.get_env(:wallaby, :screenshot_dir, "#{File.cwd!()}/screenshots")
  end

  @doc false
  def build_file_url(path) do
    "file://" <> (path |> Path.expand() |> URI.encode())
  end

  defp is_selenium?(parent) do
    parent.driver == Wallaby.Selenium
  end
end
