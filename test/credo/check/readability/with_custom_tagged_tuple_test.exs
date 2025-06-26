defmodule Credo.Check.Readability.WithCustomTaggedTupleTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.WithCustomTaggedTuple

  #
  # cases NOT raising issues
  #

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

  #
  # cases raising issues
  #

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
      [issue1, issue2] = issues

      assert issue1.message ==
               "Avoid using tagged tuples as placeholders in `with` (found: `:resource`)."

      assert issue1.trigger == ":resource"

      assert issue2.message ==
               "Avoid using tagged tuples as placeholders in `with` (found: `:authz`)."

      assert issue2.trigger == ":authz"
    end)
  end
end
