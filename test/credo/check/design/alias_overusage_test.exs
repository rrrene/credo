defmodule Credo.Check.Design.AliasOverusageTest do
  use Credo.Test.Case

  @described_check Credo.Check.Design.AliasOverusage

  test "Aliasing within the module is fine" do
    """
    defmodule MyApp.Accounts.User do
      alias MyApp.Accounts
      alias MyApp.Accounts.Role
      alias MyApp.Accounts.Secret

      def fun1 do
        Posts.Post.something
      end
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

      def fun1 do
        Posts.Post.something
      end
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

      def fun1 do
        Post.something
      end
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

      def fun1 do
        Posts.Post.something
        Brands.Brand.something_else
      end
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

      def fun1 do
        Post.something
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert Enum.map(issues, & &1.message) == [
               "You are reaching too far into another module: MyApp.Posts.Post",
               "You are reaching too far into another module: MyApp.Posts.Comment"
             ]
    end)
  end
end
