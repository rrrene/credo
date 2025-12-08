defmodule Credo.Check.Readability.StrictModuleLayoutTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.StrictModuleLayout

  describe "default order" do
    test "no errors are reported on a successful layout" do
      ~S'''
      defmodule CredoSampleModule do
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
      '''
      |> to_source_file
      |> run_check(@described_check)
      |> refute_issues
    end

    test "only first-level parts are analyzed" do
      ~S'''
      defmodule CredoSampleModule do
        @x 1

        def some_fun(), do: @x
      end
      '''
      |> to_source_file
      |> run_check(@described_check)
      |> refute_issues
    end

    test "custom macro invocations are ignored" do
      ~S'''
      defmodule CredoSampleModule do
        import Foo

        setup do
          alias Bar
          use Foo
        end
      end
      '''
      |> to_source_file
      |> run_check(@described_check)
      |> refute_issues
    end

    test "no errors are reported on surface import calls" do
      ~S'''
      defmodule HygeiaWeb.ImportLive.Header do
        @moduledoc false

        use HygeiaWeb, :surface_live_component

        alias Hygeia.ImportContext.Import
        alias Hygeia.ImportContext.Import.Type
        alias HygeiaWeb.UriActiveContext
        alias Surface.Components.LiveRedirect

        prop import, :map, required: true
      end
      '''
      |> to_source_file
      |> run_check(@described_check)
      |> refute_issues
    end

    test "shortdoc must appear before moduledoc" do
      ~S'''
      defmodule CredoSampleModule do
        @moduledoc "some doc"
        @shortdoc "shortdoc"
      end
      '''
      |> to_source_file
      |> run_check(@described_check)
      |> assert_issue(fn issue ->
        assert issue.message == "shortdoc must appear before moduledoc"
      end)
    end

    test "moduledoc must appear before behaviour" do
      ~S'''
      defmodule CredoSampleModule do
        @behaviour GenServer
        @moduledoc "some doc"
      end
      '''
      |> to_source_file
      |> run_check(@described_check)
      |> assert_issue(fn issue ->
        assert issue.message == "moduledoc must appear before behaviour"
      end)
    end

    test "behaviour must appear before use" do
      ~S'''
      defmodule CredoSampleModule do
        use GenServer
        @behaviour GenServer
      end
      '''
      |> to_source_file
      |> run_check(@described_check)
      |> assert_issue(fn issue ->
        assert issue.message == "behaviour must appear before use"
      end)
    end

    test "use must appear before import" do
      ~S'''
      defmodule CredoSampleModule do
        import GenServer
        use GenServer
      end
      '''
      |> to_source_file
      |> run_check(@described_check)
      |> assert_issue(fn issue ->
        assert issue.message == "use must appear before import"
      end)
    end

    test "import must appear before alias" do
      ~S'''
      defmodule CredoSampleModule do
        alias GenServer
        import GenServer
      end
      '''
      |> to_source_file
      |> run_check(@described_check)
      |> assert_issue(fn issue ->
        assert issue.message == "import must appear before alias"
      end)
    end

    test "alias must appear before require" do
      ~S'''
      defmodule CredoSampleModule do
        require GenServer
        alias GenServer
      end
      '''
      |> to_source_file
      |> run_check(@described_check)
      |> assert_issue(fn issue ->
        assert issue.message == "alias must appear before require"
      end)
    end

    test "callback functions and macros are handled by the `:callback_impl` option" do
      ~S'''
      defmodule CredoSampleModule do
        @impl true
        def foo

        def baz, do: :ok

        @impl true
        defmacro bar

        def qux, do: :ok
      end
      '''
      |> to_source_file
      |> run_check(@described_check, order: ~w/public_fun callback_impl/a)
      |> assert_issues(2)
      |> assert_issues_match([
        %{
          message: "public function must appear before callback implementation",
          scope: "CredoSampleModule.baz"
        },
        %{
          message: "public function must appear before callback implementation",
          scope: "CredoSampleModule.qux"
        }
      ])
    end
  end

  describe "custom order" do
    test "no errors are reported on a successful layout" do
      ~S'''
      defmodule CredoSampleModule do
        def foo, do: :ok
        defp bar, do: :ok
      end
      '''
      |> to_source_file
      |> run_check(@described_check, order: ~w/public_fun private_fun/a)
      |> refute_issues
    end

    test "no errors are reported on a custom layout missing parts defined in :order" do
      ~S'''
      defmodule CredoSampleModule do
        def foo, do: :ok
      end
      '''
      |> to_source_file
      |> run_check(@described_check, order: ~w/public_fun private_fun/a)
      |> refute_issues
    end

    test "no errors are reported on a custom layout with extra parts not defined in :order" do
      ~S'''
      defmodule CredoSampleModule do
        def foo, do: :ok

        defp bar, do: :ok

        defmacro test, do: :ok

        @moduledoc ""
      end
      '''
      |> to_source_file
      |> run_check(@described_check, order: ~w/public_fun private_fun/a)
      |> refute_issues
    end

    test "reports errors" do
      ~S'''
      defmodule CredoSampleModule do
        @moduledoc ""
        defp bar, do: :ok
        def foo, do: :ok
      end
      '''
      |> to_source_file
      |> run_check(@described_check, order: ~w/public_fun private_fun/a)
      |> assert_issues(fn [issue1, issue2] ->
        assert issue1.message == "private function must appear before moduledoc"
        assert issue1.line_no == 3

        assert issue2.message == "public function must appear before private function"
        assert issue2.line_no == 4
      end)
    end

    test "reports errors for guards" do
      ~S'''
      defmodule CredoSampleModule do
        @moduledoc ""

        defguardp is_foo(term) when term == :foo

        defguard is_bar(term) when term == :bar

        defguard is_baz(term) when not is_foo(term) and term == :baz
      end
      '''
      |> to_source_file
      |> run_check(@described_check, order: [:moduledoc, :public_guard, :private_guard])
      |> assert_issue()
    end

    test "treats `:callback_fun` as `:callback_impl` for backward compatibility" do
      ~S'''
      defmodule CredoSampleModule do
        @impl Foo
        def foo, do: :ok

        def bar, do: :ok
      end
      '''
      |> to_source_file
      |> run_check(@described_check, order: ~w/public_fun callback_fun/a)
      |> assert_issue(fn issue ->
        assert issue.message == "public function must appear before callback implementation"
      end)
    end
  end

  describe "ignored parts" do
    test "no errors are reported on ignored parts" do
      ~S'''
      defmodule CredoSampleModule do
        alias Foo
        import Bar
        use Baz
        require Qux
      end
      '''
      |> to_source_file
      |> run_check(@described_check, ignore: ~w/use import/a)
      |> refute_issues
    end

    test "no errors are reported on ignored parts for module attributes" do
      ~S'''
      defmodule CredoSampleModule do
        @moduledoc ""

        @type foo :: :foo

        def hello do
          :world
        end

        @foo :foo

        @spec foo() :: foo()
        def foo() do
          @foo
        end
      end
      '''
      |> to_source_file
      |> run_check(@described_check,
        order: [:moduledoc, :public_fun],
        ignore: [:type, :module_attribute]
      )
      |> refute_issues
    end

    test "reports errors on non-ignored parts" do
      ~S'''
      defmodule CredoSampleModule do
        require Qux
        import Bar
        use Baz
        alias Foo
      end
      '''
      |> to_source_file
      |> run_check(@described_check, ignore: ~w/use import/a)
      |> assert_issue(fn issue ->
        assert issue.message == "alias must appear before require"
      end)
    end
  end

  describe "ignored module attributes" do
    test "ignores custom module attributes" do
      ~S'''
      defmodule CredoSampleModule do
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
      '''
      |> to_source_file
      |> run_check(@described_check,
        order: ~w(use import module_attribute)a,
        ignore_module_attributes: ~w/trace/a
      )
      |> refute_issues
    end

    test "ignores enforce_keys module attribute" do
      ~S'''
      defmodule CredoSampleModule do
        @enforce_keys [:bar]
        defstruct bar: nil
      end
      '''
      |> to_source_file
      |> run_check(@described_check, order: [:defstruct, :module_attribute])
      |> refute_issues
    end

    test "only ignores set module attributes" do
      ~S'''
      defmodule CredoSampleModule do
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
      '''
      |> to_source_file
      |> run_check(@described_check,
        order: ~w(import module_attribute)a,
        ignore_module_attributes: ~w/trace/a
      )
      |> assert_issue(fn issue ->
        assert issue.message == "module attribute must appear before public function"
        # TODO: It would be nicer if the trigger was the attribute in question
        assert issue.trigger == "CredoSampleModule"
      end)
    end
  end
end
