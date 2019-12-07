defmodule Credo.Check.Warning.MixEnvTest do
  use Credo.TestHelper

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
    |> refute_issues(@described_check)
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
    |> refute_issues(@described_check)
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
    |> refute_issues(@described_check,
      excluded_paths: ["foo/dangerous_stuff"]
    )
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
    |> refute_issues(@described_check,
      excluded_paths: [~r"danger"]
    )
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
    |> assert_issue(@described_check)
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
    |> assert_issue(@described_check)
  end
end
