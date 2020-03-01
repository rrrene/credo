defmodule Credo.Check.Readability.WithCustomTaggedTupleTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.WithCustomTaggedTuple

  test "it should NOT report violation" do
    """
    defmodule Test do
      def run(user, resource) do
        with {:ok, resource} <- Resource.fetch(user),
             :ok <- Resource.authorize(resource, user),
             do: SomeMod.do_something(resource)
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report a violation" do
    """
    defmodule Test do
      def run(user, resource) do
        with {:resource, {:ok, resource}} <- {:resource, Resource.fetch(user)},
             {:authz, :ok} <- {:authz, Resource.authorize(resource, user)} do
          SomeMod.do_something(resource)
        else
          {:resource, _} -> {:error, :not_found}
          {:authz, _} -> {:error, :unauthorized}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      issue_messages = Enum.map(issues, & &1.message)

      assert Enum.member?(issue_messages, "Invalid usage of placeholder `:resource` in with")
      assert Enum.member?(issue_messages, "Invalid usage of placeholder `:authz` in with")
    end)
  end
end
