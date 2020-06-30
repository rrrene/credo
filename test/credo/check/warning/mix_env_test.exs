defmodule Credo.Check.Warning.MixEnvTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.MixEnv

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report on instance in exs file" do
    """
    defmodule CredoSampleModule do
      def some_function do
        Mix.env()
      end
    end
    """
    |> to_source_file("foo.exs")
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report on instance in excluded string path" do
    """
    defmodule CredoSampleModule do
      def some_function do
        Mix.env()
      end
    end
    """
    |> to_source_file("foo/dangerous_stuff/bar.ex")
    |> run_check(@described_check, excluded_paths: ["foo/dangerous_stuff"])
    |> refute_issues()
  end

  test "it should NOT report on instance in excluded regex path" do
    """
    defmodule CredoSampleModule do
      def some_function do
        Mix.env()
      end
    end
    """
    |> to_source_file("foo/dangerous_stuff/bar.ex")
    |> run_check(@described_check, excluded_paths: [~r"danger"])
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      def some_function do
        Mix.env()
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /2" do
    """
    defmodule CredoSampleModule do
      def some_function do
        &Mix.env/0
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
