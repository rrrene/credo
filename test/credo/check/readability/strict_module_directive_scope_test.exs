defmodule Credo.Check.Readability.StrictModuleDirectiveScopeTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.StrictModuleDirectiveScope

  describe "module-level directives" do
    test "allows directives at module level" do
      """
      defmodule CredoSampleModule do
        alias Foo.Bar
        require Logger
        import Enum
        use GenServer
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end

    test "allows nested module with its own directives" do
      """
      defmodule CredoSampleModule do
        alias Foo

        defmodule Nested do
          alias Bar
          require Logger
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end
  end

  describe "basic function-level directives" do
    test "reports alias in public function" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def process do
            alias Foo.Bar
            Bar.do_something()
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Alias Foo.Bar should be defined at module level, not inside function process"
      assert issue.trigger == "alias"
      assert issue.line_no == 3
    end

    test "reports require in public function" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def log_it do
            require Logger
            Logger.info("test")
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Require Logger should be defined at module level, not inside function log_it"
    end

    test "reports import in public function" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def process(list) do
            import Enum
            map(list, & &1 * 2)
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Import Enum should be defined at module level, not inside function process"
    end

    test "reports use in public function" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def setup do
            use MyBehaviour
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Use MyBehaviour should be defined at module level, not inside function setup"
    end

    test "reports alias in private function by default" do
      [issue] =
        """
        defmodule CredoSampleModule do
          defp helper do
            alias Foo.Bar
            Bar.help()
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message ==
               "Alias Foo.Bar should be defined at module level, not inside private function helper"
    end

    test "reports directive in macro" do
      [issue] =
        """
        defmodule CredoSampleModule do
          defmacro create_thing do
            require Logger
            Logger.info("creating")
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Require Logger should be defined at module level, not inside macro create_thing"
    end

    test "reports multiple directives in same function" do
      assert [issue1, issue2] =
               """
               defmodule CredoSampleModule do
                 def process do
                   alias Foo.Bar
                   require Logger
                   Logger.info("processing")
                   Bar.process()
                 end
               end
               """
               |> to_source_file()
               |> run_check(@described_check)
               |> assert_issues()

      assert issue1.message == "Alias Foo.Bar should be defined at module level, not inside function process"
      assert issue2.message == "Require Logger should be defined at module level, not inside function process"
    end
  end

  describe "nested control structures" do
    test "reports alias in if block" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def check(x) do
            if x > 10 do
              alias Foo.Bar
              Bar.process(x)
            end
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Alias Foo.Bar should be defined at module level, not inside function check"
    end

    test "reports alias in else block" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def check(x) do
            if x > 10 do
              :ok
            else
              alias Foo.Bar
              Bar.process(x)
            end
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Alias Foo.Bar should be defined at module level, not inside function check"
    end

    test "reports alias in case clause" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def handle(msg) do
            case msg do
              :ok ->
                alias Foo.Success
                Success.handle()

              :error ->
                :error
            end
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Alias Foo.Success should be defined at module level, not inside function handle"
    end

    test "reports alias in cond clause" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def check(x) do
            cond do
              x > 10 ->
                alias Foo.Big
                Big.process(x)

              true ->
                :small
            end
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Alias Foo.Big should be defined at module level, not inside function check"
    end

    test "reports alias in with statement do block" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def process(data) do
            with {:ok, value} <- fetch(data) do
              alias Foo.Processor
              Processor.process(value)
            end
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Alias Foo.Processor should be defined at module level, not inside function process"
    end

    test "reports alias in with statement else block" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def process(data) do
            with {:ok, value} <- fetch(data) do
              :ok
            else
              :error ->
                alias Foo.ErrorHandler
                ErrorHandler.handle()
            end
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Alias Foo.ErrorHandler should be defined at module level, not inside function process"
    end

    test "reports alias in try-rescue block" do
      assert [issue1, issue2] =
               """
               defmodule CredoSampleModule do
                 def process do
                   try do
                     alias Foo.Worker
                     Worker.do_risky_thing()
                   rescue
                     e in RuntimeError ->
                       alias Foo.ErrorHandler
                       ErrorHandler.handle(e)
                   end
                 end
               end
               """
               |> to_source_file()
               |> run_check(@described_check)
               |> assert_issues()

      assert issue1.message == "Alias Foo.Worker should be defined at module level, not inside function process"
      assert issue2.message == "Alias Foo.ErrorHandler should be defined at module level, not inside function process"
    end

    test "reports alias in try-catch block" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def process do
            try do
              risky_thing()
            catch
              :error, reason ->
                alias Foo.ErrorHandler
                ErrorHandler.handle(reason)
            end
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Alias Foo.ErrorHandler should be defined at module level, not inside function process"
    end

    test "reports alias in try-after block" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def process do
            try do
              risky_thing()
            after
              alias Foo.Cleanup
              Cleanup.cleanup()
            end
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Alias Foo.Cleanup should be defined at module level, not inside function process"
    end
  end

  describe "multi-clause functions" do
    test "reports alias in multiple clauses" do
      assert [issue1, issue2] =
               """
               defmodule CredoSampleModule do
                 def handle(:ok) do
                   alias Foo.Success
                   Success.handle()
                 end

                 def handle(:error) do
                   alias Foo.Failure
                   Failure.handle()
                 end
               end
               """
               |> to_source_file()
               |> run_check(@described_check)
               |> assert_issues()

      assert issue1.message == "Alias Foo.Success should be defined at module level, not inside function handle"
      assert issue2.message == "Alias Foo.Failure should be defined at module level, not inside function handle"
    end

    test "reports alias in when guards" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def handle(x) when is_integer(x) do
            alias Foo.Bar
            Bar.handle(x)
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message == "Alias Foo.Bar should be defined at module level, not inside function handle"
    end
  end

  describe "configuration: directives" do
    test "only checks specified directives" do
      """
      defmodule CredoSampleModule do
        def process do
          alias Foo.Bar
          require Logger
          import Enum
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check, directives: [:alias])
      |> assert_issue(fn issue ->
        assert issue.message =~ "Alias Foo.Bar"
      end)
    end

    test "checks multiple specified directives" do
      assert [issue1, issue2] =
               """
               defmodule CredoSampleModule do
                 def process do
                   alias Foo.Bar
                   require Logger
                   import Enum
                   use GenServer
                 end
               end
               """
               |> to_source_file()
               |> run_check(@described_check, directives: [:alias, :use])
               |> assert_issues()

      assert issue1.message =~ "Alias Foo.Bar"
      assert issue2.message =~ "Use GenServer"
    end

    test "ignores directives not in the list" do
      """
      defmodule CredoSampleModule do
        def process do
          require Logger
          import Enum
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check, directives: [:alias, :use])
      |> refute_issues()
    end
  end

  describe "configuration: allow_in_private_functions" do
    test "allows directives in private functions when configured" do
      """
      defmodule CredoSampleModule do
        defp helper do
          alias Foo.Bar
          require Logger
          Bar.help()
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check, allow_in_private_functions: true)
      |> refute_issues()
    end

    test "still checks public functions when private allowed" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def public_fun do
            alias Foo.Bar
            Bar.help()
          end

          defp private_fun do
            alias Foo.Baz
            Baz.help()
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check, allow_in_private_functions: true)
        |> assert_issue()

      assert issue.message =~ "Alias Foo.Bar"
      assert issue.message =~ "function public_fun"
    end

    test "allows directives in private macros when configured" do
      """
      defmodule CredoSampleModule do
        defmacrop helper do
          alias Foo.Bar
          quote do: Bar.help()
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check, allow_in_private_functions: true)
      |> refute_issues()
    end
  end

  describe "configuration: allow_in_test_macros" do
    test "allows directives in setup block by default" do
      """
      defmodule CredoSampleModuleTest do
        use ExUnit.Case

        setup do
          alias MyApp.Factory
          {:ok, user: Factory.insert(:user)}
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end

    test "allows directives in test block by default" do
      """
      defmodule CredoSampleModuleTest do
        use ExUnit.Case

        test "something works" do
          alias MyApp.Helper
          assert Helper.works?()
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end

    test "allows directives in describe block by default" do
      """
      defmodule CredoSampleModuleTest do
        use ExUnit.Case

        describe "feature" do
          alias MyApp.Feature

          test "works" do
            assert Feature.works?()
          end
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end

    test "reports directives in test blocks when configured strict" do
      [issue] =
        """
        defmodule CredoSampleModuleTest do
          use ExUnit.Case

          test "something works" do
            alias MyApp.Helper
            assert Helper.works?()
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check, allow_in_test_macros: false)
        |> assert_issue()

      assert issue.message =~ "Alias MyApp.Helper"
    end
  end

  describe "configuration: allow_in_quote_blocks" do
    test "allows directives in quote blocks by default" do
      """
      defmodule CredoSampleModule do
        defmacro create_thing do
          quote do
            alias Foo.Bar
            Bar.create()
          end
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end

    test "reports directives outside quote in macro" do
      [issue] =
        """
        defmodule CredoSampleModule do
          defmacro create_thing do
            alias Foo.Helper
            Helper.validate()

            quote do
              create_the_thing()
            end
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message =~ "Alias Foo.Helper"
      assert issue.message =~ "macro create_thing"
    end

    test "reports directives in quote blocks when configured strict" do
      [issue] =
        """
        defmodule CredoSampleModule do
          defmacro create_thing do
            quote do
              alias Foo.Bar
              Bar.create()
            end
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check, allow_in_quote_blocks: false)
        |> assert_issue()

      assert issue.message =~ "Alias Foo.Bar"
    end
  end

  describe "configuration: exclude_functions" do
    test "excludes functions matching regex pattern" do
      """
      defmodule CredoSampleModule do
        def render_form do
          alias MyAppWeb.Components
          Components.form()
        end

        def process do
          alias Foo.Bar
          Bar.process()
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check, exclude_functions: [~r/^render/])
      |> assert_issue(fn issue ->
        assert issue.message =~ "Alias Foo.Bar"
        assert issue.message =~ "function process"
      end)
    end

    test "excludes multiple function patterns" do
      """
      defmodule CredoSampleModule do
        def render_form do
          alias MyAppWeb.Components
          Components.form()
        end

        def helper_test do
          alias Test.Helper
          Helper.help()
        end

        def process do
          alias Foo.Bar
          Bar.process()
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check, exclude_functions: [~r/^render/, ~r/_test$/])
      |> assert_issue(fn issue ->
        assert issue.message =~ "Alias Foo.Bar"
        assert issue.message =~ "function process"
      end)
    end

    test "handles empty exclusion list" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def render do
            alias Foo
            Foo.bar()
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check, exclude_functions: [])
        |> assert_issue()

      assert issue.message =~ "Alias Foo"
    end
  end

  describe "edge cases" do
    test "handles functions with no body" do
      """
      defmodule CredoSampleModule do
        def foo
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end

    test "handles functions with single expression body" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def foo, do: (alias Foo; Foo.bar())
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message =~ "Alias Foo"
    end

    test "handles empty modules" do
      """
      defmodule CredoSampleModule do
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end

    test "handles modules with only module attributes" do
      """
      defmodule CredoSampleModule do
        @moduledoc "docs"
        @foo 42
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end

    test "reports directive without explicit module name" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def foo do
            alias __MODULE__.Bar
            Bar.baz()
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message =~ "Alias"
      assert issue.trigger == "alias"
    end
  end

  describe "anonymous functions and comprehensions" do
    test "reports alias in anonymous function" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def process(data) do
            Enum.map(data, fn x ->
              alias Foo.Processor
              Processor.process(x)
            end)
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message =~ "Alias Foo.Processor"
      assert issue.message =~ "function process"
    end

    test "reports alias in for comprehension" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def process(items) do
            for x <- items do
              alias Foo.Processor
              Processor.process(x)
            end
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message =~ "Alias Foo.Processor"
      assert issue.message =~ "function process"
    end

    test "reports alias in unless block" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def check(x) do
            unless x > 10 do
              alias Foo.Small
              Small.process(x)
            end
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message =~ "Alias Foo.Small"
      assert issue.message =~ "function check"
    end

    test "reports alias in nested anonymous function" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def transform(data) do
            Enum.map(data, fn item ->
              Enum.map(item.children, fn child ->
                alias Foo.Transform
                Transform.apply(child)
              end)
            end)
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message =~ "Alias Foo.Transform"
    end

    test "reports multiple directives in for comprehension" do
      assert [issue1, issue2] =
               """
               defmodule CredoSampleModule do
                 def process(items) do
                   for x <- items do
                     alias Foo.Validator
                     require Logger
                     Logger.debug("Processing")
                     Validator.validate(x)
                   end
                 end
               end
               """
               |> to_source_file()
               |> run_check(@described_check)
               |> assert_issues()

      assert issue1.message =~ "Alias Foo.Validator"
      assert issue2.message =~ "Require Logger"
    end
  end

  describe "alias with options" do
    test "reports alias with :as option" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def process do
            alias Foo.Bar, as: Baz
            Baz.process()
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message =~ "Alias Foo.Bar"
      assert issue.message =~ "function process"
    end

    test "reports import with :only option" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def process(list) do
            import Enum, only: [map: 2]
            map(list, & &1 * 2)
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message =~ "Import Enum"
      assert issue.message =~ "function process"
    end

    test "reports require with :as option" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def log do
            require Logger, as: L
            L.info("test")
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message =~ "Require Logger"
      assert issue.message =~ "function log"
    end
  end

  describe "real-world patterns" do
    test "LiveView component with inline aliases" do
      [issue] =
        """
        defmodule MyAppWeb.UserComponent do
          use Phoenix.LiveComponent

          def render(assigns) do
            alias MyAppWeb.Components.Avatar

            ~H\"\"\"
            <div>
              <Avatar.render user={@user} />
            </div>
            \"\"\"
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message =~ "Alias MyAppWeb.Components.Avatar"
    end

    test "allows LiveView render when excluded" do
      """
      defmodule MyAppWeb.UserComponent do
        use Phoenix.LiveComponent

        def render(assigns) do
          alias MyAppWeb.Components.Avatar

          ~H\"\"\"
          <div>
            <Avatar.render user={@user} />
          </div>
          \"\"\"
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check, exclude_functions: [~r/^render/])
      |> refute_issues()
    end

    test "test helper with setup block" do
      """
      defmodule MyAppTest do
        use ExUnit.Case

        setup do
          alias MyApp.Factory
          alias MyApp.Repo

          {:ok, user: Factory.insert(:user), repo: Repo}
        end

        test "creates user" do
          alias MyApp.Users
          assert Users.create(%{name: "John"})
        end
      end
      """
      |> to_source_file()
      |> run_check(@described_check)
      |> refute_issues()
    end

    test "conditional requires in function" do
      [issue] =
        """
        defmodule CredoSampleModule do
          def maybe_log(condition, msg) do
            if condition do
              require Logger
              Logger.info(msg)
            end
          end
        end
        """
        |> to_source_file()
        |> run_check(@described_check)
        |> assert_issue()

      assert issue.message =~ "Require Logger"
    end
  end
end
