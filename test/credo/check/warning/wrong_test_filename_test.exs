defmodule Credo.Check.Warning.WrongTestFilenameTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.WrongTestFilename

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code in lib/ files" do
    """
    defmodule MyModule do
      use GenServer
      use Phoenix.LiveView
      use MyApp.Cases
      use MyApp.Cases, async: true
      use MyApp.Cases, async: true, group: :some_group
    end
    """
    |> to_source_file("lib/my_module.ex")
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code in test/ files" do
    """
    defmodule MyModuleTest do
      use ExUnit.Case
      use ExUnit.Case, async: true
      use ExUnit.Case, async: false, group: :some_group
    end
    """
    |> to_source_file("test/my_module_test.exs")
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report an issue for using a module with a name ending in 'Case'" do
    """
    defmodule MyModuleTest do
      use MyApp.ConnCase
      use MyApp.ConnCase, async: true
      use MyApp.ConnCase, async: false, group: :some_group
    end
    """
    |> to_source_file("test/my_module_test.exs")
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report an issue for using anything in a quote block" do
    """
    defmodule MyModule do
      defmacro foo(_opts) do
        quote do
          use MyApp.ConnCase
        end
      end
    end
    """
    |> to_source_file("lib/my_module.ex")
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation when used in a misnamed test/ file (_text instead of _test)" do
    """
    defmodule MyModule do
      use ExUnit.Case, async: true
    end
    """
    |> to_source_file("test/my_module_text.exs")
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when used in a misnamed test/ file (.ex instead of .exs)" do
    """
    defmodule MyModule do
      use ExUnit.Case, async: true
    end
    """
    |> to_source_file("test/my_module_test.ex")
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when used in a non-test file" do
    """
    defmodule MyModule do
      use MyApp.ConnCase
    end
    """
    |> to_source_file("lib/my_module.ex")
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when used with options in a non-test file" do
    """
    defmodule MyModule do
      use MyApp.ConnCase, async: false, group: :some_group
    end
    """
    |> to_source_file("lib/my_module.ex")
    |> run_check(@described_check)
    |> assert_issue()
  end
end
