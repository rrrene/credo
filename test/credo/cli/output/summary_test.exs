defmodule Credo.CLI.Output.SummaryTest do
  use Credo.TestHelper

  alias Credo.CLI.Output.Summary
  alias Credo.Execution

  doctest Credo.CLI.Output.Summary

  test "print/4 it does not blow up on an empty umbrella project" do
    config =
      %Credo.Execution{}
      |> Credo.Execution.SourceFiles.start_server
      |> Credo.Execution.Issues.start_server
    Summary.print([], config, 0, 0)
  end
end
