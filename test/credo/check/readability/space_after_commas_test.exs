defmodule Credo.Check.Readability.SpaceAfterCommasTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.SpaceAfterCommas

  #
  # cases NOT raising issues
  #

  test "it should NOT report when commas have spaces" do
    """
    # comments should not matter [[[,]]]
    defmodule CredoSampleModule do
      @attribute {:foo, :bar}
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when commas are in interpolations" do
    ~S"""
    defmodule SpaceMissing1 do
      @moduledoc false

      @doc false
      def test_credo do
        foo = 1
        bar = 2
        _ = "#{foo} #{bar}"
        _ = Enum.join([1, 2, 3], ",") # comma in the second argument is reported
        _ = ~r"," # comma is reported
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when commas have newlines" do
    """
    defmodule CredoSampleModule do
      defstruct foo: nil,
                bar: nil
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report commas in sigils" do
    """
    defmodule CredoSampleModule do
      def fun(value) do
        Regex.match?(~r/^\\d{1,2}\\/\\d{1,2}\\/\\d{4}$/, value)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT require spaces after commas preceded by the `?` operator" do
    """
    defmodule CredoSampleModule do
      @some_char_codes [?,, ?;]
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it does not get confused by ' in a comment" do
    """
    defmodule CredoSampleModule do
      def fun do
        # '
        ','
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

  test "it should report when commas are not followed by spaces" do
    """
    defmodule CredoSampleModule do
      @attribute {:foo,:bar}
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert 19 == issue.column
      assert ",:" == issue.trigger
    end)
  end

  test "it should report when there are many commas not followed by spaces" do
    """
    defmodule CredoSampleModule do
      @attribute [1,2,"three",4,5]
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert 4 == Enum.count(issues)
      assert [16, 18, 26, 28] == Enum.map(issues, & &1.column)
      assert [",2", ",\"", ",4", ",5"] == Enum.map(issues, & &1.trigger)
    end)
  end

  test "it requires spaces after commas preceded by the `?,`" do
    """
    defmodule CredoSampleModule do
      @some_char_codes [?,,?;]
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it requires spaces after commas preceded by variables ending with a ?" do
    """
    defmodule CredoSampleModule do
      @attribute [question?,answer]
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it requires spaces after commas followed by [" do
    """
    defmodule CredoSampleModule do
      @attribute [foo,[bar]]
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
