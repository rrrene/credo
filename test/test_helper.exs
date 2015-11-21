ExUnit.start()

# Exclude all external tests from running
ExUnit.configure(exclude: [to_be_implemented: true])

defmodule Credo.TestHelper do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case
      import CredoSourceFileCase
      import CredoCheckCase
    end
  end
end

defmodule Credo.Test.FilenameGenerator do
  use GenServer

  @table_name __MODULE__

  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def next do
    number = GenServer.call(__MODULE__, {:next})
    "test-untitled.#{number}.ex"
  end

  # callbacks

  def init(_) do
    {:ok, 1}
  end

  def handle_call({:next}, _from, current_state) do
    {:reply, current_state+1, current_state+1}
  end
end

defmodule Credo.TestApplication do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Credo.Test.FilenameGenerator, []),
    ]

    opts = [strategy: :one_for_one, name: Credo.TestApplication.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

Credo.TestApplication.start([], [])

defmodule CredoSourceFileCase do
  alias Credo.Test.FilenameGenerator

  def to_source_file(source) do
    filename = FilenameGenerator.next
    case Credo.SourceFile.parse(source, filename) do
      %{valid?: true} = source_file -> source_file
      _ -> raise "Source could not be parsed!"
    end
  end

  def to_source_files(list) do
    list
    |> Enum.with_index
    |> Enum.map(fn({source, index}) ->
        to_source_file(source)
      end)
  end
end

defmodule CredoCheckCase do
  use ExUnit.Case

  def refute_issues(source_file, check \\ nil, config \\ []) do
    issues = issues_for(source_file, check, config)
    assert [] == issues, "There should be no issues, got #{Enum.count(issues)}: #{to_inspected(issues)}"
    issues
  end

  def assert_issue(source_file, callback) when is_function(callback) do
    assert_issue(source_file, nil, [], callback)
  end
  def assert_issue(source_file, check, callback) when is_function(callback) do
    assert_issue(source_file, check, [], callback)
  end

  def assert_issue(source_file, check \\ nil, config \\ [], callback \\ nil) do
    issues = issues_for(source_file, check, config)
    refute Enum.count(issues) == 0, "There should be an issue."
    assert Enum.count(issues) == 1, "There should be only 1 issue, got #{Enum.count(issues)}: #{to_inspected(issues)}"
    if callback, do: callback.(issues |> List.first)
    issues
  end

  def assert_issues(source_file, callback) when is_function(callback) do
    assert_issues(source_file, nil, [], callback)
  end
  def assert_issues(source_file, check, callback) when is_function(callback) do
    assert_issues(source_file, check, [], callback)
  end
  def assert_issues(source_file, check \\ nil, config \\ [], callback \\ nil) do
    issues = issues_for(source_file, check, config)
    assert Enum.count(issues) > 0, "There should be issues."
    assert Enum.count(issues) > 1, "There should be more than one issue, got: #{to_inspected(issues)}"
    if callback, do: callback.(issues)
    issues
  end

  defp issues_for(source_files, nil, _) when is_list(source_files) do
    source_files
    |> Enum.flat_map(&(&1.issues))
  end
  defp issues_for(source_files, check, config) when is_list(source_files) do
    source_files
    |> check.run(config)
    |> Enum.flat_map(&(&1.issues))
  end
  defp issues_for(source_file, nil, _), do: source_file.issues
  defp issues_for(source_file, check, config), do: check.run(source_file, config)


  def assert_trigger([issue], trigger), do: [assert_trigger(issue, trigger)]
  def assert_trigger(issue, trigger) do
    assert trigger == issue.trigger
    issue
  end

  def to_inspected(value) do
    value
    |> Inspect.Algebra.to_doc(%Inspect.Opts{})
    |> Inspect.Algebra.format(50)
    |> Enum.join("")
  end
end
