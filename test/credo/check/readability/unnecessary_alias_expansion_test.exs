defmodule Credo.Check.Readability.UnnecessaryAliasExpansionTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.UnnecessaryAliasExpansion

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation" do
    """
    defmodule Test do
      alias App.Module1
      alias App.{Module2, Module3}
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation /2" do
    """
    defmodule MyMacro do
      defmacro my_macro do
        quote do
          defmodule MySubmodule do
            alias alias!(MyAliasedModule)

            def test do
              IO.puts(MyAliasedModule)
            end
          end
        end
      end

      defmacro my_dsl(do: block) do
        quote do
          alias __MODULE__.MyAliasedModule

          defmodule MyAliasedModule do
          end

          unquote(block)
        end
      end
    end

    defmodule MyModule do
      import MyMacro

      my_dsl do
        my_macro
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      alias App.Module1
      alias App.Module2.{Module3}
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for double expansion" do
    """
    defmodule CredoSampleModule do
      alias App.Module1
      alias App.{Module2}.{Module3}
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "Module3"
    end)
  end
end
