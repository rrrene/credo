defmodule Credo.CLI.Output.IssuesGroupedByCategory do
  use Credo.CLI.Output.Delegator,
    default: Credo.CLI.Output.IssuesGroupedByCategory.Default,
    flycheck: Credo.CLI.Output.IssuesGroupedByCategory.FlyCheck,
    oneline: Credo.CLI.Output.IssuesGroupedByCategory.Oneline,
    json: Credo.CLI.Output.IssuesGroupedByCategory.Json
end
