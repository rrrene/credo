defmodule Credo.Check.HousekeepingTriggerTest do
  use Credo.Test.Case

  @tag housekeeping: :trigger
  test "find trigger assertions" do
    errors =
      Path.join(__DIR__, "*/**/*_test.exs")
      |> Path.wildcard()
      |> Enum.reject(&String.match?(&1, ~r/(collector|helper)/))
      |> Enum.reject(
        &String.match?(
          &1,
          ~r/(wrong_test_file|unreachable_code|regex_multiple_spaces|regex_empty_character_classes|module_size|case_trivial_matches|perceived_complexity|duplicated_code)/
        )
      )
      |> Enum.map(&{&1, File.read!(&1)})
      |> Enum.flat_map(fn {filename, source} ->
        ast = Code.string_to_quoted!(source)

        {_ast, acc} =
          Macro.prewalk(ast, [], fn
            {:test, _, [_ | _] = args}, acc ->
              Macro.prewalk(args, acc, fn
                {op, _, [_ | _] = args2}, acc when op in [:assert_issue, :assert_issues] ->
                  Macro.prewalk(args2, acc, fn
                    {:fn, _, args3}, acc ->
                      Macro.prewalk(args3, acc, fn
                        {{:., _, [{_issue, _, nil}, :trigger]}, _, []} = ast, acc ->
                          {ast, [{:ok, filename}] ++ acc}

                        ast, acc ->
                          {ast, acc}
                      end)

                    ast, acc ->
                      {ast, acc}
                  end)

                ast, acc ->
                  {ast, acc}
              end)

            ast, acc ->
              {ast, acc}
          end)

        if acc == [] do
          [
            "- #{Path.relative_to_cwd(filename)}:1"
          ]
        else
          []
        end
      end)

    if errors != [] do
      flunk(
        "Expected to find at least one assertion for `:trigger` to make sure it's the right one:\n" <>
          Enum.join(errors, "\n")
      )
    end
  end
end
