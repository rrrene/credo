defmodule Credo.Check.Readability.ModuleDocTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.ModuleDoc

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      @moduledoc "Something"
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report controller submodules" do
    """
    defmodule MyApp.SomePhoenixController do
      defmodule SubModule do
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report .exs scripts" do
    """
    defmodule ModuleTest do
      defmodule SubModule do
      end
    end
    """
    |> to_source_file("module_doc_test_1.exs")
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should not report exception modules" do
    """
    defmodule CredoSampleModule do
      defexception message: "Bad luck"
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
      def some_fun do
        x = 1; y = 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report empty strings" do
    """
    defmodule CredoSampleModule do
      @moduledoc ""
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report empty multi line strings" do
    """
    defmodule CredoSampleModule do
      @moduledoc \"\"\"

      \"\"\"
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
