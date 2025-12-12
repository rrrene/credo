defmodule Credo.Check.Warning.RaiseInsideRescueTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.RaiseInsideRescue

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def catcher do
        try do
          raise "oops"
        rescue
          e in RuntimeError ->
            Logger.warn("Something bad happened")
          e ->
            reraise e, System.stacktrace
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /2" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def catcher do
        try do
          raise "oops"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation when raise appears inside of a rescue block" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def catcher do
        try do
          raise "oops"
        rescue
          e in RuntimeError ->
            Logger.warn("Something bad happened")
            raise e
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 10, column: 9, trigger: "raise"})
  end

  test "it should report a violation when raise appears inside of a rescue block for an implicit try" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def catcher do
        raise "oops"
      rescue
        e in RuntimeError ->
          Logger.warn("Something bad happened")
          raise e
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 9, column: 7, trigger: "raise"})
  end

  test "it should report a violation when raise appears inside of an expression in rescue" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def catcher do
        try do
          raise "oops"
        rescue
          e -> Logger.warn("Something bad happened") && raise e
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 8, column: 53, trigger: "raise"})
  end

  test "it should report multiple violations" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def catcher do
        try do
          raise "oops"
        rescue
          e ->
            if is_nil(e) do
              Logger.warn("Something bad happened") && raise e
            else
              raise e
            end
        end
      end

      def catcher do
        raise "oops"
      rescue
        e ->
          if is_nil(e) do
            Logger.warn("Something bad happened") && raise e
          else
            raise e
          end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(4)
  end
end
