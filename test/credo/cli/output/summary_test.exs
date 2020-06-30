defmodule Credo.CLI.Output.SummaryTest do
  use Credo.Test.Case

  alias Credo.CLI.Output.Summary
  alias Credo.Execution

  doctest Credo.CLI.Output.Summary

  test "print/4 it does not blow up on an empty umbrella project" do
    exec = Execution.build()

    Summary.print([], exec, 0, 0)
  end
end
