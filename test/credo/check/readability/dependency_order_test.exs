defmodule Credo.Check.Readability.DependencyOrderTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.DependencyOrder

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation" do
    """
    defmodule Test do
      defp deps do
        [
          {:a, "~> 0.0.1"},
          {:b, "~> 0.0.1", only: :dev},
          {:x, "~> 0.0.1"},
          {:z, "~> 0.0.1", runtime: false}
        ]
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end
end
