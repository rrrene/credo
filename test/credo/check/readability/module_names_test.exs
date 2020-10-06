defmodule Credo.Check.Readability.ModuleNamesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.ModuleNames

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report acronyms in module names" do
    """
    defmodule CredoHTTPModule do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report if module name cannot be determinated" do
    """
    defmacro foo(quoted_module) do
      {module, []} = Code.eval_quoted(quoted_module)
      quote do
        defmodule unquote(module).Bar do
        end
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

  test "it should report a violation /2" do
    """
    defmodule Credo_SampleModule do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
