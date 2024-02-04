defmodule Credo.Check.HousekeepingHeredocsInTestsTest do
  use Credo.Test.Case

  @tag housekeeping: :heredocs
  test "find triple-double-quote heredocs in check tests" do
    errors =
      Path.join(__DIR__, "*/**/*_test.exs")
      |> Path.wildcard()
      |> Enum.reject(&String.match?(&1, ~r/(collector|helper)/))
      |> Enum.map(&{&1, File.read!(&1)})
      |> Enum.flat_map(fn {filename, source} ->
        ast =
          source
          |> Code.string_to_quoted!(
            literal_encoder: &{:ok, {:__literal__, &2, [&1]}},
            token_metadata: true
          )
          |> Macro.prewalk(fn
            {op, params, args} -> {op, Map.new(params), args}
            val -> val
          end)

        {_ast, acc} =
          Macro.prewalk(ast, [], fn
            {:__literal__, %{line: line, delimiter: "\"\"\""}, [val]} = ast, acc
            when is_binary(val) ->
              {ast, ["#{filename}:#{line}"] ++ acc}

            ast, acc ->
              {ast, acc}
          end)

        acc
      end)

    if errors != [] do
      flunk(
        "Expected to use ~s or ~S heredocs:\n" <>
          Enum.join(errors, "\n")
      )
    end
  end
end
