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

    defmodule Credo.AnotherModule.SampleModule do
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

  test "it should NOT report if module name cannot be determined" do
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

  test "it should NOT raise on ignored module" do
    """
    defmodule Sample_Module do
    end
    """
    |> to_source_file
    |> run_check(@described_check, ignore: ["Sample_Module"])
    |> refute_issues()
  end

  test "it should NOT raise on ignored pattern" do
    """
    defmodule Sample_Module do
    end
    """
    |> to_source_file
    |> run_check(@described_check, ignore: [~r/Sample_Module/])
    |> refute_issues()
  end

  test "it should NOT raise on ignored segment when multiple are present" do
    """
    defmodule Credo.Another_Module.SampleModule do
    end
    """
    |> to_source_file
    |> run_check(@described_check, ignore: [~r/Another_Module/])
    |> refute_issues()
  end

  test "it should NOT raise on multiple ignored segment patterns" do
    """
    defmodule Credo.Another_Module.Sample_Module do
    end
    """
    |> to_source_file
    |> run_check(@described_check, ignore: [~r/Another_Module\.Sample_Module/])
    |> refute_issues()
  end

  test "it should NOT raise on multiple ignored segment patterns for binary" do
    """
    defmodule Credo.Another_Module.Sample_Module do
    end
    """
    |> to_source_file
    |> run_check(@described_check, ignore: ["Credo.Another_Module.Sample_Module"])
    |> refute_issues()
  end

  test "it should NOT raise on multiple ignored segment patterns for atom" do
    """
    defmodule Credo.Another_Module.Sample_Module do
    end
    """
    |> to_source_file
    |> run_check(@described_check, ignore: [Credo.Another_Module.Sample_Module])
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

  test "it should report a violation for invalid segment" do
    """
    defmodule Credo.Sample_Module do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "Credo.Sample_Module"
    end)
  end

  test "it should report a violation with multiple segments when one is invalid" do
    """
    defmodule Credo.Another_Module.Sample_Module do
    end
    """
    |> to_source_file
    |> run_check(@described_check, ignore: [~r/Another_Module$/])
    |> assert_issue(fn issue ->
      assert issue.trigger == "Credo.Another_Module.Sample_Module"
    end)
  end
end
