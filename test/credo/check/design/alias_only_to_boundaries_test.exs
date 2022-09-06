defmodule Credo.Check.Design.AliasOnlyToBoundariesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Design.AliasOnlyToBoundaries

  # Tests about aliasing too deeply

  test "Aliasing within the module is fine" do
    """
    defmodule MyApp.Accounts.User do
      alias MyApp.Accounts
      alias MyApp.Accounts.Role
      alias MyApp.Accounts.Secret
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "Aliasing to a different second-level module to access it's submodules" do
    """
    defmodule MyApp.Accounts.User do
      alias MyApp.Posts
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "Aliasing to a different second-level module's submodule directly" do
    """
    defmodule MyApp.Accounts.User do
      alias MyApp.Posts.Post
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "Multi-aliasing to a different second-level module to access it's submodules" do
    """
    defmodule MyApp.Accounts.User do
      alias MyApp.{Posts, Brands}
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "Multi-aliasing to a different second-level module's submodule directly" do
    """
    defmodule MyApp.Accounts.User do
      alias MyApp.Posts.{Post, Comment}
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert Enum.map(issues, & &1.message) == [
               "You are aliasing too far into another module: MyApp.Posts.Post (suggestion: `alias MyApp.Posts`)",
               "You are aliasing too far into another module: MyApp.Posts.Comment (suggestion: `alias MyApp.Posts`)"
             ]
    end)
  end

  test "Deep modules test" do
    """
    defmodule MyApp.Accounts.Users.User do
      alias MyAppWeb.GraphQL

      alias MyApp

      alias MyApp.Billing
      alias MyApp.Billing.Bill

      alias MyApp.Accounts
      alias MyApp.Accounts.Authorization
      alias MyApp.Accounts.Authorization.Hashing

      alias MyApp.Accounts.Users
      alias MyApp.Accounts.Users.Role
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert Enum.map(issues, & &1.message) == [
               "You are aliasing too far into another module: MyAppWeb.GraphQL (suggestion: `alias MyAppWeb`)",
               "You are aliasing too far into another module: MyApp.Billing.Bill (suggestion: `alias MyApp.Billing`)",
               "You are aliasing too far into another module: MyApp.Accounts.Authorization.Hashing (suggestion: `alias MyApp.Accounts.Authorization`)"
             ]
    end)
  end

  test "Handling aliasing with `as`" do
    """
    defmodule MyApp.Accounts.User do
      alias MyApp.Posts.Post, as: PostFoo
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.message ==
               "You are aliasing too far into another module: MyApp.Posts.Post (suggestion: `alias MyApp.Posts`)"
    end)
  end

  test "Specifying exceptions" do
    """
    defmodule MyApp.Accounts.User do
      alias MyApp.Posts.Category
      alias MyApp.Posts.{Post, Comment}
    end
    """
    |> to_source_file
    |> run_check(@described_check, exceptions: ~w[
      MyApp.Posts.Category
      MyApp.Posts.Comment
    ])
    |> assert_issue(fn issue ->
      assert issue.message ==
               "You are aliasing too far into another module: MyApp.Posts.Post (suggestion: `alias MyApp.Posts`)"
    end)
  end

  # Tests about not aliasing far enough

  test "No aliasing when reference is deep should suggest an alias" do
    """
    defmodule MyApp.Accounts.User do
      def name do
        MyApp.Accounts.Role

        MyApp.Posts.Post

        MyApp.Posts.Post.Details

        MyAppWeb.Something
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert Enum.map(issues, & &1.message) == [
               "Nested modules could be aliased at the top of the invoking module. (suggestion: `alias MyApp.Accounts.Role`)",
               "Nested modules could be aliased at the top of the invoking module. (suggestion: `alias MyApp.Posts`)",
               "Nested modules could be aliased at the top of the invoking module. (suggestion: `alias MyApp.Posts`)"
               # No point in aliasing just one level
               # "Nested modules could be aliased at the top of the invoking module. (suggestion: `alias MyAppWeb`)"
             ]
    end)
  end

  test "Should be fine when the alias is specified" do
    """
    defmodule MyApp.Accounts.User do
      alias MyApp.Posts

      def name do
        Posts.Post
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "TODO" do
    """
    defmodule MyApp.Accounts.Auth.User do
      alias MyApp.Accounts
      alias MyApp.Sales

      def name do
        Accounts.Auth.Role

        Sales.Targeting.User

        MyAppWeb.Something
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.message ==
               "Nested modules could be aliased at the top of the invoking module. (suggestion: `alias MyApp.Accounts.Auth.Role`)"

      "Nested modules could be aliased at the top of the invoking module. (suggestion: `alias MyApp.Accounts.Auth.Role`)"
    end)
  end
end
