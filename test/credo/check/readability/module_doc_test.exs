defmodule Credo.Check.Readability.ModuleDocTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.ModuleDoc

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      @moduledoc "Something"
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report controller submodules" do
    ~S'''
    defmodule MyApp.SomePhoenixController do
      defmodule SubModule do
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report .exs scripts" do
    ~S'''
    defmodule ModuleTest do
      defmodule SubModule do
      end
    end
    '''
    |> to_source_file("module_doc_test_1.exs")
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report exception modules" do
    ~S'''
    defmodule CredoSampleModule do
      defexception message: "Bad luck"
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report modules or submodules when @moduledoc is present" do
    ~S'''
    defmodule Foo do
      @moduledoc false

      defmodule Bar do
        @moduledoc false
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, ignore_names: [])
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    ~S'''
    defmodule CredoSampleModule do
      def some_fun do
        x = 1; y = 2
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report modules when @moduledoc is present in submodules only" do
    ~S'''
    defmodule Foo do
      # distinctly no moduledoc here
      defmodule Bar do
        @moduledoc false
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, ignore_names: [])
    |> assert_issue()
  end

  test "it should report empty strings" do
    ~S'''
    defmodule CredoSampleModule do
      @moduledoc ""
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "CredoSampleModule"
    end)
  end

  test "it should report empty multi line strings" do
    ~S'''
    defmodule CredoSampleModule do
      @moduledoc """

      """
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "CredoSampleModule"
    end)
  end

  test "it should report slightly unexpected code" do
    ~S'''
    defmodule Person, do: def(greet(), do: :howdy)
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "Person"
    end)
  end

  test "it should report controller submodules when the :ignore_names param says so" do
    ~S'''
    defmodule MyApp.SomePhoenixController do
      defmodule SubModule do
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, ignore_names: [])
    |> assert_issues()
  end
end
