defmodule Credo.Check.Readability.StrictModuleLayout do
  use Credo.Check,
    base_priority: :low,
    tags: [:controversial],
    explanations: [
      check: """
      Provide module parts in a required order.

          # preferred

          defmodule MyMod do
            @moduledoc "moduledoc"
            use Foo
            import Bar
            alias Baz
            require Qux
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        order: """
        List of atoms identifying the desired order of module parts.

        Supported values are:

        - `:moduledoc` - `@moduledoc` module attribute
        - `:shortdoc` - `@shortdoc` module attribute
        - `:behaviour` - `@behaviour` module attribute
        - `:use` - `use` expression
        - `:import` - `import` expression
        - `:alias` - `alias` expression
        - `:require` - `require` expression
        - `:defstruct` - `defstruct` expression
        - `:opaque` - `@opaque` module attribute
        - `:type` - `@type` module attribute
        - `:typep` - `@typep` module attribute
        - `:callback` - `@callback` module attribute
        - `:macrocallback` - `@macrocallback` module attribute
        - `:optional_callbacks` - `@optional_callbacks` module attribute
        - `:module_attribute` - other module attribute
        - `:public_fun` - public function
        - `:private_fun` - private function or a public function marked with `@doc false`
        - `:public_macro` - public macro
        - `:private_macro` - private macro or a public macro marked with `@doc false`
        - `:callback_impl` - public function or macro marked with `@impl`
        - `:public_guard` - public guard
        - `:private_guard` - private guard or a public guard marked with `@doc false`
        - `:module` - inner module definition (`defmodule` expression inside a module)

        Notice that the desired order always starts from the top.

        For example, if you provide the order `~w/public_fun private_fun/a`,
        it means that everything else (e.g. `@moduledoc`) must appear after
        function definitions.
        """,
        ignore: """
        List of atoms identifying the module parts which are not checked, and may
        therefore appear anywhere in the module. Supported values are the same as
        in the `:order` param.
        """
      ]
    ],
    param_defaults: [
      order: ~w/shortdoc moduledoc behaviour use import alias require/a,
      ignore: []
    ]

  alias Credo.Code
  alias Credo.CLI.Output.UI

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    params = normalize_params(params)

    source_file
    |> Code.ast()
    |> Credo.Code.Module.analyze()
    |> all_errors(params, IssueMeta.for(source_file, params))
    |> Enum.sort_by(&{&1.line_no, &1.column})
  end

  defp normalize_params(params) do
    order =
      params
      |> Params.get(:order, __MODULE__)
      |> Enum.map(fn element ->
        # TODO: This is done for backward compatibility and should be removed in some future version.
        with :callback_fun <- element do
          UI.warn([
            :red,
            "** (StrictModuleLayout) Check param `:callback_fun` has been deprecated. Use `:callback_impl` instead.\n\n",
            "  Use `mix credo explain #{Credo.Code.Module.name(__MODULE__)}` to learn more. \n"
          ])

          :callback_impl
        end
      end)

    Keyword.put(params, :order, order)
  end

  defp all_errors(modules_and_parts, params, issue_meta) do
    expected_order = expected_order(params)
    ignored_parts = Keyword.get(params, :ignore, [])

    Enum.reduce(
      modules_and_parts,
      [],
      fn {module, parts}, errors ->
        parts =
          parts
          |> Stream.map(fn
            # Converting `callback_macro` and `callback_fun` into a common `callback_impl`,
            # because enforcing an internal order between these two kinds is counterproductive if
            # a module implements multiple behaviours. In such cases, we typically want to group
            # callbacks by the implementation, not by the kind (fun vs macro).
            {callback_impl, location} when callback_impl in ~w/callback_macro callback_fun/a ->
              {:callback_impl, location}

            other ->
              other
          end)
          |> Stream.reject(fn {part, _location} -> part in ignored_parts end)

        module_errors(module, parts, expected_order, issue_meta) ++ errors
      end
    )
  end

  defp expected_order(params) do
    params
    |> Keyword.fetch!(:order)
    |> Enum.with_index()
    |> Map.new()
  end

  defp module_errors(module, parts, expected_order, issue_meta) do
    Enum.reduce(
      parts,
      %{module: module, current_part: nil, errors: []},
      &check_part_location(&2, &1, expected_order, issue_meta)
    ).errors
  end

  defp check_part_location(state, {part, file_pos}, expected_order, issue_meta) do
    state
    |> validate_order(part, file_pos, expected_order, issue_meta)
    |> Map.put(:current_part, part)
  end

  defp validate_order(state, part, file_pos, expected_order, issue_meta) do
    if is_nil(state.current_part) or
         order(state.current_part, expected_order) <= order(part, expected_order),
       do: state,
       else: add_error(state, part, file_pos, issue_meta)
  end

  defp order(part, expected_order), do: Map.get(expected_order, part, map_size(expected_order))

  defp add_error(state, part, file_pos, issue_meta) do
    update_in(
      state.errors,
      &[error(issue_meta, part, state.current_part, state.module, file_pos) | &1]
    )
  end

  defp error(issue_meta, part, current_part, module, file_pos) do
    format_issue(
      issue_meta,
      message: "#{part_to_string(part)} must appear before #{part_to_string(current_part)}",
      trigger: inspect(module),
      line_no: Keyword.get(file_pos, :line),
      column: Keyword.get(file_pos, :column)
    )
  end

  defp part_to_string(:module_attribute), do: "module attribute"
  defp part_to_string(:public_guard), do: "public guard"
  defp part_to_string(:public_macro), do: "public macro"
  defp part_to_string(:public_fun), do: "public function"
  defp part_to_string(:private_fun), do: "private function"
  defp part_to_string(:callback_impl), do: "callback implementation"
  defp part_to_string(part), do: "#{part}"
end
