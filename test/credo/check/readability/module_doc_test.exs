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

  test "it should NOT report modules when using :ignore_names matches" do
    source_file =
      ~S'''
      defmodule CredoSampleModule do
        def some_fun, do: :ok
      end
      '''
      |> to_source_file

    source_file
    |> run_check(@described_check, ignore_names: [CredoSampleModule])
    |> refute_issues()

    source_file
    |> run_check(@described_check, ignore_names: ["CredoSampleModule"])
    |> refute_issues()

    source_file
    |> run_check(@described_check, ignore_names: [~r/SampleModule$/])
    |> refute_issues()

    source_file
    |> run_check(@described_check, ignore_names: [CredoSampleModule, "MyApp.Web", ~r/Other/])
    |> refute_issues()
  end

  test "it should NOT report modules when using :ignore_modules_using matches" do
    source_file =
      ~S'''
      defmodule CredoSampleModule do
        use MyApp.Web, :controller
      end
      '''
      |> to_source_file()

    source_file
    |> run_check(@described_check, ignore_modules_using: [MyApp.Web])
    |> refute_issues()

    source_file
    |> run_check(@described_check, ignore_modules_using: ["MyApp.Web"])
    |> refute_issues()

    source_file
    |> run_check(@described_check, ignore_modules_using: [~r/\.Web$/])
    |> refute_issues()

    source_file
    |> run_check(@described_check, ignore_modules_using: [GenServer, "MyApp.Web", ~r/Other/])
    |> refute_issues()
  end

  test "it should NOT report submodules when using :ignore_modules_using matches" do
    ~S'''
    defmodule CredoSampleModule do
      @moduledoc "Parent"

      defmodule Child do
        use MyApp.Web, :controller
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check, ignore_modules_using: ["MyApp.Web"])
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
    |> assert_issue(%{line_no: 1, trigger: "CredoSampleModule"})
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
    |> assert_issue(%{line_no: 1, trigger: "CredoSampleModule"})
  end

  test "it should report slightly unexpected code" do
    ~S'''
    defmodule Person, do: def(greet(), do: :howdy)
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 1, trigger: "Person"})
  end

  test "it should report modules when using :ignore_modules_using does not match" do
    ~S'''
    defmodule CredoSampleModule do
      use SomethingElse
    end
    '''
    |> to_source_file
    |> run_check(@described_check, ignore_modules_using: ["MyApp.Web"])
    |> assert_issue()
  end

  test "it should report modules when using empty :ignore_modules_using" do
    ~S'''
    defmodule CredoSampleModule do
      use MyApp.Web, :controller
    end
    '''
    |> to_source_file
    |> run_check(@described_check, ignore_modules_using: [])
    |> assert_issue()
  end

  test "it should report controller submodules when using :ignore_names" do
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
