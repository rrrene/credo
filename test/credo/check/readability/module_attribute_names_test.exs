defmodule Credo.Check.Readability.ModuleAttributeNamesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.ModuleAttributeNames

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      @some_foobar
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT fail on a dynamic attribute" do
    """
    defmodule CredoSampleModule do
      defmacro define(key, value) do
        quote do
          @unquote(key)(unquote(value))
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT fail when redefining the @ operator" do
    """
    defmodule CredoSampleModule do
      defmacro @{_, _, _} do
        quote do
          # some_code_here
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

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      @someFoobar false
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
