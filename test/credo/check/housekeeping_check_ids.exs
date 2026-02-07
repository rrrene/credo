defmodule Credo.Check.HousekeepingParamsTest do
  use Credo.Test.Case

  @tag housekeeping: :ids
  test "find double or missing ids in checks" do
    {%{
       configs: [
         %{checks: checks}
       ]
     }, _} = Code.eval_file(".credo.exs")

    all_checks =
      Enum.map(checks.disabled ++ checks.enabled, fn {check_mod, _params} ->
        {check_mod.id(), check_mod}
      end)
      |> Enum.sort()

    duplicate_checks =
      all_checks
      |> Enum.group_by(&elem(&1, 0))
      |> Enum.reject(fn {_key, values} -> length(values) == 1 end)

    if duplicate_checks != [] do
      flunk(
        "Expected to find no duplicate check IDs, but found these:\n" <>
          inspect(duplicate_checks, pretty: true)
      )
    end
  end
end
