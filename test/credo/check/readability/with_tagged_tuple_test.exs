defmodule Credo.Check.Readability.WithTaggedTupleTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.WithTaggedTuple

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
    |> refute_issues(@described_check)
  end

  test "it should report a violation" do
    issue_messages =
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
      |> assert_issues(@described_check)
      |> Enum.map(& &1.message)

    assert MapSet.new(issue_messages) ==
             MapSet.new([
               "Invalid usage of placeholder `:resource` in with",
               "Invalid usage of placeholder `:authz` in with"
             ])
  end
end
