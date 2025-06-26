defmodule Credo.Check.Readability.StrictModuleLayoutTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.StrictModuleLayout

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

    test "no errors are reported on surface import calls" do
      """
      defmodule HygeiaWeb.ImportLive.Header do
        @moduledoc false

        use HygeiaWeb, :surface_live_component

        alias Hygeia.ImportContext.Import
        alias Hygeia.ImportContext.Import.Type
        alias HygeiaWeb.UriActiveContext
        alias Surface.Components.LiveRedirect

        prop import, :map, required: true
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

    test "callback functions and macros are handled by the `:callback_impl` option" do
      assert [issue1, issue2] =
               """
               defmodule Test do
                 @impl true
                 def foo

                 def baz, do: :ok

                 @impl true
                 defmacro bar

                 def qux, do: :ok
               end
               """
               |> to_source_file
               |> run_check(@described_check, order: ~w/public_fun callback_impl/a)
               |> assert_issues

      assert issue1.message == "public function must appear before callback implementation"
      assert issue1.scope == "Test.baz"

      assert issue2.message == "public function must appear before callback implementation"
      assert issue2.scope == "Test.qux"
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

    test "treats `:callback_fun` as `:callback_impl` for backward compatibility" do
      [issue] =
        """
        defmodule Test do
          @impl Foo
          def foo, do: :ok

          def bar, do: :ok
        end
        """
        |> to_source_file
        |> run_check(@described_check, order: ~w/public_fun callback_fun/a)
        |> assert_issue

      assert issue.message == "public function must appear before callback implementation"
    end
  end

  describe "ignored parts" do
    test "no errors are reported on ignored parts" do
      """
      defmodule Test do
        alias Foo
        import Bar
        use Baz
        require Qux
      end
      """
      |> to_source_file
      |> run_check(@described_check, ignore: ~w/use import/a)
      |> refute_issues
    end

    test "reports errors on non-ignored parts" do
      [issue] =
        """
        defmodule Test do
          require Qux
          import Bar
          use Baz
          alias Foo
        end
        """
        |> to_source_file
        |> run_check(@described_check, ignore: ~w/use import/a)
        |> assert_issue

      assert issue.message == "alias must appear before require"
    end
  end

  describe "ignored module attributes" do
    test "ignores custom module attributes" do
      """
      defmodule Test do
        use Baz

        import Bar

        @trace trace_fun()
        def test_fun() do
          nil
        end

        @trace trace_fun()
        def test() do
          nil
        end
      end
      """
      |> to_source_file
      |> run_check(@described_check,
        order: ~w(use import module_attribute)a,
        ignore_module_attributes: ~w/trace/a
      )
      |> refute_issues
    end

    test "ignores enforce_keys module attribute" do
      """
      defmodule Test do
        @enforce_keys [:bar]
        defstruct bar: nil
      end
      """
      |> to_source_file
      |> run_check(@described_check, order: [:defstruct, :module_attribute])
      |> refute_issues
    end

    test "only ignores set module attributes" do
      """
      defmodule Test do
        import Bar

        @trace trace_fun()
        def test_fun() do
          nil
        end

        @bad_attribute
        @trace trace_fun()
        def test() do
          nil
        end
      end
      """
      |> to_source_file
      |> run_check(@described_check,
        order: ~w(import module_attribute)a,
        ignore_module_attributes: ~w/trace/a
      )
      |> assert_issue(fn issue ->
        assert issue.message == "module attribute must appear before public function"
        # TODO: It would be nicer if the trigger was the attribute in question
        assert issue.trigger == "Test"
      end)
    end
  end
end
