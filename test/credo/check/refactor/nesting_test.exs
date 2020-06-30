defmodule Credo.Check.Refactor.NestingTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.Nesting

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if parameter1 do
          do_something
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when there are multiple if's on the same level" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if parameter1 do
          do_something
        end
        if parameter2 do
          do_something
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when there are multiple if's on the same level 2" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if parameter1 do
          case parameter1 do
            0 -> nil
            1 -> do_something
          end
        end
        if parameter2 do
          if parameter1 do
            do_something
          end
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if parameter1 do
          if parameter2 do
            case parameter1 do
              0 -> nil
              1 -> do_something
            end
          end
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation 2" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        case parameter1 do
          0 -> nil
          1 ->
            if parameter1 do
              if parameter2 do
                do_something
              end
            end
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation 3" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        if parameter1 do
          case parameter1 do
            0 -> nil
            1 ->
              if parameter2, do: do_something
          end
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation 4" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Enum.reduce(var1, list, fn({_hash, nodes}, list) ->
          filenames = nodes |> Enum.map(&(&1.filename))
          Enum.reduce(list, [], fn(item, acc) ->
            if Enum.member?(filenames, item.filename) do
              item # this is nested 3 levels deep
            end
            acc ++ [item]
          end)
        end)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
