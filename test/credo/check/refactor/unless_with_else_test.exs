defmodule Credo.Check.Refactor.UnlessWithElseTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.UnlessWithElse

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        unless allowed? do
          something
        end
        if allowed? do
          something
        else
          something_else
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
        unless allowed? do
          something
        else
          something_else
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  describe "autocorrect/2" do
    test "changes the unless with else to an if clause" do
      starting = """
      defmodule CredoSampleModule do
        def some_function(parameter1, parameter2) do
          unless allowed? do
            unless other_condition? do
              something
            end
          else
            something_else
          end
        end
      end
      """

      expected = """
      defmodule CredoSampleModule do
        def some_function(parameter1, parameter2) do
          if allowed? do
            something_else
          else
            unless other_condition? do
              something
            end
          end
        end
      end
      """

      assert @described_check.autocorrect(starting, nil) == expected
    end
  end
end
