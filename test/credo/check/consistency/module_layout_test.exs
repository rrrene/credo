defmodule Credo.Check.Consistency.ModuleLayoutTest do
  use Credo.Test.Case

  @described_check Credo.Check.Consistency.ModuleLayout

  describe "default order" do
    test "no errors are reported on a successful layout" do
      """
      defmodule Test do
        @shortdoc "shortdoc"
        @moduledoc "some doc"

        @behaviour GenServer
        @behaviour Supervisor

        use GenServer

        import GenServer

        alias GenServer
        alias Mod1.{Mod2, Mod3}

        require GenServer
      end
      """
      |> to_source_file
      |> run_check(@described_check)
      |> refute_issues
    end

    test "only first-level parts are analyzed" do
      """
      defmodule Test do
        @x 1

        def some_fun(), do: @x
      end
      """
      |> to_source_file
      |> run_check(@described_check)
      |> refute_issues
    end

    test "custom macro invocations are ignored" do
      """
      defmodule Test do
        import Foo

        setup do
          alias Bar
          use Foo
        end
      end
      """
      |> to_source_file
      |> run_check(@described_check)
      |> refute_issues
    end

    test "shortdoc must appear before moduledoc" do
      [issue] =
        """
        defmodule Test do
          @moduledoc "some doc"
          @shortdoc "shortdoc"
        end
        """
        |> to_source_file
        |> run_check(@described_check)
        |> assert_issue

      assert issue.message == "shortdoc must appear before moduledoc"
    end

    test "moduledoc must appear before behaviour" do
      [issue] =
        """
        defmodule Test do
          @behaviour GenServer
          @moduledoc "some doc"
        end
        """
        |> to_source_file
        |> run_check(@described_check)
        |> assert_issue

      assert issue.message == "moduledoc must appear before behaviour"
    end

    test "behaviour must appear before use" do
      [issue] =
        """
        defmodule Test do
          use GenServer
          @behaviour GenServer
        end
        """
        |> to_source_file
        |> run_check(@described_check)
        |> assert_issue

      assert issue.message == "behaviour must appear before use"
    end

    test "use must appear before import" do
      [issue] =
        """
        defmodule Test do
          import GenServer
          use GenServer
        end
        """
        |> to_source_file
        |> run_check(@described_check)
        |> assert_issue

      assert issue.message == "use must appear before import"
    end

    test "import must appear before alias" do
      [issue] =
        """
        defmodule Test do
          alias GenServer
          import GenServer
        end
        """
        |> to_source_file
        |> run_check(@described_check)
        |> assert_issue

      assert issue.message == "import must appear before alias"
    end

    test "alias must appear before require" do
      [issue] =
        """
        defmodule Test do
          require GenServer
          alias GenServer
        end
        """
        |> to_source_file
        |> run_check(@described_check)
        |> assert_issue

      assert issue.message == "alias must appear before require"
    end
  end

  describe "custom order" do
    test "no errors are reported on a successful layout" do
      """
      defmodule Test do
        def foo, do: :ok
        defp bar, do: :ok
      end
      """
      |> to_source_file
      |> run_check(@described_check, order: ~w/public_fun private_fun/a)
      |> refute_issues
    end

    test "reports errors" do
      assert [issue1, issue2] =
               """
               defmodule Test do
                 @moduledoc ""
                 defp bar, do: :ok
                 def foo, do: :ok
               end
               """
               |> to_source_file
               |> run_check(@described_check, order: ~w/public_fun private_fun/a)
               |> assert_issues

      assert issue1.message == "private function must appear before moduledoc"
      assert issue1.line_no == 3

      assert issue2.message == "public function must appear before private function"
      assert issue2.line_no == 4
    end
  end
end
