defmodule Credo.Check.Consistency.ModuleLayout do
  use Credo.Check,
    run_on_all: true,
    base_priority: :low,
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
      """,
      params: [
        order: """
        List of atoms identifying the desired order of module parts.
        Defaults to  `~w/shortdoc moduledoc behaviour use import alias require/a`.

        Following values can be provided:

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
            - `:callback_fun` - public function marked with `@impl`
            - `:public_macro` - public macro
            - `:private_macro` - private macro or a public macro marked with `@doc false`
            - `:public_guard` - public guard
            - `:private_guard` - private guard or a public guard marked with `@doc false`
            - `:module` - inner module definition (`defmodule` expression inside a module)

        Notice that the desired order always starts from the top. For example, if you provide
        the order `~w/public_fun private_fun/a`, it means that everything else (e.g. `@moduledoc`)
        must appear after function definitions.
        """
      ]
    ]

  alias Credo.Code

  @doc false
  def run(source_file, params \\ []) do
    source_file
    |> Code.ast()
    |> Credo.Check.Module.analyze()
    |> all_errors(expected_order(params), IssueMeta.for(source_file, params))
    |> Enum.sort_by(&{&1.line_no, &1.column})
  end

  defp expected_order(params) do
    params
    |> Keyword.get(:order, ~w/shortdoc moduledoc behaviour use import alias require/a)
    |> Enum.with_index()
    |> Map.new()
  end

  defp all_errors(modules_and_parts, expected_order, issue_meta) do
    Enum.reduce(
      modules_and_parts,
      [],
      fn {module, parts}, errors ->
        module_errors(module, parts, expected_order, issue_meta) ++ errors
      end
    )
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
  defp part_to_string(:callback_fun), do: "callback implementation"
  defp part_to_string(part), do: "#{part}"
end
