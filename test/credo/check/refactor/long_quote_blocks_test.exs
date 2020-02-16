defmodule Credo.Check.Refactor.LongQuoteBlocksTest do
  use Credo.Test.Case

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
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation if comments are ignored" do
    """
    defmodule CredoSampleModule do
      defmacro __using__(opts) do
        quote do
          def some_fun do
            # This
            # is
            # a
            # rather
            # long
            # comment
            # block
            # ...
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
    |> run_check(@described_check, max_line_count: 7, ignore_comments: true)
    |> refute_issues()
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
    |> run_check(@described_check, max_line_count: 2)
    |> assert_issue()
  end

  test "it should report a violation if comments are NOT ignored" do
    """
    defmodule CredoSampleModule do
      defmacro __using__(opts) do
        quote do
          def some_fun do
            # This
            # is
            # a
            # rather
            # long
            # comment
            # block
            # ...
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
    |> run_check(@described_check, max_line_count: 7)
    |> assert_issue()
  end
end
