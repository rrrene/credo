defmodule Credo.Check.Refactor.LongQuoteBlocksTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.LongQuoteBlocks

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      defmacro __using__(opts) do
        quote do
          def some_fun do
            some_stuff()
          end
        end
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      defmacro __using__(opts) do
        quote do
          def some_fun do
            some_stuff()
          end

          def some_fun do
            some_stuff()
          end
        end
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check, max_line_count: 2)
  end
end
