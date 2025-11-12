defmodule Credo.Check.Warning.MixEnvTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.MixEnv

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report on instance in exs file" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function do
        Mix.env()
      end
    end
    '''
    |> to_source_file("foo.exs")
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report on instance in excluded string path" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function do
        Mix.env()
      end
    end
    '''
    |> to_source_file("foo/dangerous_stuff/bar.ex")
    |> run_check(@described_check, excluded_paths: ["foo/dangerous_stuff"])
    |> refute_issues()
  end

  test "it should NOT report on instance in excluded regex path" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function do
        Mix.env()
      end
    end
    '''
    |> to_source_file("foo/dangerous_stuff/bar.ex")
    |> run_check(@described_check, excluded_paths: [~r"danger"])
    |> refute_issues()
  end

  test "it should NOT report on instance in module attributes" do
    ~S'''
    defmodule CredoSampleModule do
      @myvar Mix.env() == :test

      def test do
        @myvar
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report outside of functions" do
    ~S'''
    defmodule CredoSampleModule do
      @myvar Mix.env() == :test

      if Mix.env() in [:dev, :test] do
        import Phoenix.LiveDashboard.Router

        scope "/" do
          pipe_through :browser

          live_dashboard "/dashboard", metrics: HelloWeb.Telemetry
        end
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function do
        Mix.env()
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /2" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function do
        &Mix.env/0
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 3
      assert issue.trigger == "Mix.env"
    end)
  end

  test "it should report a violation with two on the same line" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Mix.env(); Mix.env()
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn [two, one] ->
      assert one.line_no == 3
      assert one.column == 5
      assert two.line_no == 3
      assert two.column == 16
    end)
  end

  test "it should report violations from variables named like def operations" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function do
        def = Mix.env()
        defp = &Mix.env/0
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end
end
