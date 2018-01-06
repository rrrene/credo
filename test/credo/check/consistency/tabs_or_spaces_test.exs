defmodule Credo.Check.Consistency.TabsOrSpacesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.TabsOrSpaces

  @with_tabs """
  defmodule Credo.Sample do
  \t@test_attribute :foo

  \tdef foobar(parameter1, parameter2) do
  \t\tString.split(parameter1) + parameter2
  \tend
  end
  """
  @with_spaces """
  defmodule Credo.Sample do
    defmodule InlineModule do
      def foobar do
        {:ok} = File.read
      end
    end
  end
  """
  @with_spaces2 """
  defmodule OtherModule do
    defmacro foo do
      {:ok} = File.read
    end

    defp bar do
      :ok
    end
  end
  """

  #
  # cases NOT raising issues
  #

  test "it should NOT report for only tabs" do
    [
      @with_tabs
    ]
    |> to_source_files
    |> refute_issues(@described_check)
  end

  test "it should NOT report for only spaces" do
    [
      @with_spaces,
      @with_spaces2
    ]
    |> to_source_files
    |> refute_issues(@described_check)
  end

  #
  # cases NOT raising issues
  #

  @tag :to_be_implemented
  test "it should NOT report for forced, valid props" do
    [
      @with_spaces,
      @with_spaces2
    ]
    |> to_source_files
    |> assert_issues(@described_check, force: :spaces)
  end

  test "it should report for mixed indentation" do
    [
      @with_tabs,
      @with_spaces,
      @with_spaces2
    ]
    |> to_source_files
    |> assert_issues(@described_check)
  end

  @tag :to_be_implemented
  test "it should report for forced, consistent, but invalid props" do
    [
      @with_spaces,
      @with_spaces2
    ]
    |> to_source_files
    |> assert_issues(@described_check, force: :tabs)
  end
end
