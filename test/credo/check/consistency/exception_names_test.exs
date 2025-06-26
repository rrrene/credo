defmodule Credo.Check.Consistency.ExceptionNamesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Consistency.ExceptionNames

  #
  # cases NOT raising issues
  #

  test "it should NOT report modules without defexception" do
    [
      ~S"""
      defmodule UriParserError
      """,
      ~S"""
      defmodule SomeOtherException
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report correct behaviour (same suffix)" do
    [
      ~S"""
      defmodule Credo.Sample do
        defmodule UriParserError do
          defexception [:message]
        end
      end
      """,
      ~S"""
      defmodule SomeOtherError do
        defexception [:message]
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report correct behaviour (same prefix)" do
    [
      ~S"""
      defmodule Credo.Sample do
        defmodule InvalidSomething do
          defexception [:message]
        end
      end
      """,
      ~S"""
      defmodule InvalidResponse do
        defexception [:message]
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report correct behaviour (only one exception class)" do
    [
      ~S"""
      defmodule Credo.SampleError do
        defexception [:message]
      end
      """,
      ~S"""
      defmodule SomeModule do

      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for different naming schemes for 1:1 situations" do
    [
      ~S"""
      defmodule Credo.Sample do
        defmodule SomeError do
          defexception [:message]
        end
      end
      """,
      ~S"""
      defmodule UndefinedResponse do
        defexception [:message]
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should not report (prefixes)" do
    [
      ~S"""
        defmodule FactoryUndefined do
          defexception [:message]

          def exception(factory_name) do
            message = "No factory defined for this."
            %UndefinedFactory{message: message}
          end
        end

        defmodule SaveUndefined do
          defexception [:message]
        end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation for different naming schemes (suffixes)" do
    [
      ~S"""
      defmodule Credo.Sample do
        defmodule SomeException do
          defexception [:message]
        end
        defmodule UndefinedResponse do    # <--- does not have the suffix "Exception"
          defexception [:message]
        end
      end
      """,
      ~S"""
      defmodule InputValidationException do
        defexception [:message]
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 5
      assert issue.trigger == "UndefinedResponse"
    end)
  end

  test "it should report a violation for different naming schemes (prefixes)" do
    [
      ~S"""
      defmodule Credo.Sample do
        defmodule InvalidDataRequest do
          defexception [:message]
        end
      end
      """,
      ~S"""
      defmodule InvalidReponseFromServer do
        defexception [:message]
      end
      """,
      ~S"""
      defmodule UndefinedDataFormat do    # <--- does not have the prefix "Invalid"
        defexception [:message]
      end
      """
    ]
    |> to_source_files
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "UndefinedDataFormat"
    end)
  end
end
