defmodule Credo.Check.Refactor.WithAssignmentTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.WithAssignment

  test "it should NOT report when using <- in with blocks" do
    """
    defmodule CredoSampleModule do
      def some_function(id) do
        with {:ok, user} <- get_user(id),
             {:ok, profile} <- get_profile(user) do
          {:ok, %{user: user, profile: profile}}
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report when using = in with blocks" do
    """
    defmodule CredoSampleModule do
      def some_function(id) do
        with user = get_user(id),
             {:ok, profile} <- get_profile(user) do
          {:ok, %{user: user, profile: profile}}
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 3
      assert issue.trigger == "="
    end)
  end

  test "it should report multiple = assignments in with blocks" do
    """
    defmodule CredoSampleModule do
      def some_function(id) do
        with user = get_user(id),
             {:ok, profile} <- get_profile(user),
             settings = get_settings(user) do
          {:ok, %{user: user, profile: profile, settings: settings}}
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert length(issues) == 2
      assert Enum.at(issues, 0).line_no == 3
      assert Enum.at(issues, 1).line_no == 5
    end)
  end

  test "it should NOT report regular assignments outside with blocks" do
    """
    defmodule CredoSampleModule do
      def some_function(id) do
        user = get_user(id)
        
        with {:ok, profile} <- get_profile(user) do
          settings = get_settings(user)
          {:ok, %{user: user, profile: profile, settings: settings}}
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should handle with blocks with else clauses" do
    """
    defmodule CredoSampleModule do
      def some_function(id) do
        with user = get_user(id),
             {:ok, profile} <- get_profile(user) do
          {:ok, %{user: user, profile: profile}}
        else
          {:error, reason} -> {:error, reason}
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 3
      assert issue.trigger == "="
    end)
  end
end
