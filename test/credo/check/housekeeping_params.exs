defmodule Ast do
  defmacro collect(ast, pattern1, blocks \\ []) do
    do_block1 = blocks[:do]

    {pattern1, guards} =
      case pattern1 do
        {:when, _, [pattern1, guards]} -> {pattern1, guards}
        _ -> {pattern1, true}
      end

    quote do
      Macro.prewalk(unquote(ast), [], fn
        m_i_ast = unquote(pattern1), m_i_acc when unquote(guards) ->
          m_i_result = unquote(do_block1)

          {m_i_ast, List.wrap(m_i_result) ++ m_i_acc}

        ast, acc ->
          {ast, acc}
      end)
      |> then(fn {_ast, acc} -> acc end)
    end
  end
end

defmodule Credo.Check.HousekeepingHeredocsInTestsTest do
  use Credo.Test.Case

  require Ast
  import Ast

  @tag housekeeping: :params
  test "find untested params in check tests" do
    errors =
      Path.join(__DIR__, "*/**/*_test.exs")
      |> Path.wildcard()
      |> Enum.reject(&String.match?(&1, ~r/(collector|helper)/))
      |> Enum.map(&{&1, File.read!(&1)})
      |> Enum.map(fn {filename, test_source} ->
        check_filename =
          filename
          |> String.replace("/test/", "/lib/")
          |> String.replace("_test.exs", ".ex")

        check_source =
          if File.exists?(check_filename) do
            File.read!(check_filename)
          else
            ""
          end

        check_ast = Code.string_to_quoted!(check_source)

        all_param_names =
          collect check_ast, {:use, _, [{:__aliases__, _, [:Credo, :Check]}, opts]} do
            defaults = List.wrap(opts[:param_defaults])
            explanations = List.wrap(opts[:explanations][:params])

            Enum.uniq(Keyword.keys(defaults) ++ Keyword.keys(explanations))
          end

        test_ast = Code.string_to_quoted!(test_source)

        tested_params =
          collect test_ast, {:test, _, args} when is_list(args) do
            collect args, {:run_check, _, [_check, params]} do
              Keyword.keys(params)
            end
          end

        untested_params = all_param_names -- tested_params

        if check_source != "" && untested_params != [] do
          "- #{Credo.Code.Module.name(check_ast)} - untested params: #{inspect(untested_params)}"
        end
      end)
      |> Enum.reject(&is_nil/1)

    if errors != [] do
      flunk(
        "Expected to find at least one test for each param to make sure it works:\n" <>
          Enum.join(errors, "\n")
      )
    end
  end
end
