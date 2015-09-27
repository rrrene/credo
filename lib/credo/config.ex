defmodule Credo.Config do
  defstruct files:    nil,
            rules:    nil

  @config_filename ".credo.json"
  @default_files_included ["lib/**/*.{ex,exs}"]
  @default_files_excluded []

  @default_rules [
      {Dogma.Rule.BarePipeChainStart},
      {Dogma.Rule.ComparisonToBoolean},
      {Dogma.Rule.DebuggerStatement},
      {Dogma.Rule.FinalCondition},
      {Dogma.Rule.FinalNewline},
      {Dogma.Rule.FunctionArity, max: 4},
      {Dogma.Rule.FunctionName},
      {Dogma.Rule.HardTabs},
      {Dogma.Rule.LineLength, max_length: 80},
      {Dogma.Rule.LiteralInCondition},
      {Dogma.Rule.LiteralInInterpolation},
      {Dogma.Rule.MatchInCondition},
      {Dogma.Rule.ModuleAttributeName},
      {Dogma.Rule.ModuleDoc},
      {Dogma.Rule.ModuleName},
      {Dogma.Rule.NegatedIfUnless},
      {Dogma.Rule.PredicateName},
      {Dogma.Rule.TrailingBlankLines},
      {Dogma.Rule.UnlessElse},
      {Dogma.Rule.VariableName},
      {Dogma.Rule.WindowsLineEndings},
    ]

  def default_rules, do: @default_rules

  def read_or_default(dir) do
    case File.read(Path.join(dir, @config_filename)) do
      {:ok, body} -> from_json(body)
      {:error, _} -> from_json
    end
  end

  def from_json(json_string \\ "{}") do
    data = Poison.decode!(json_string)

    %Credo.Config{
      files: files_from_json(data),
      rules: rules_from_json(data)
    }
  end

  defp files_from_json(data) do
    files = data["files"] || %{}
    %{
      included: files["included"] || @default_files_included,
      excluded: files["excluded"] || @default_files_excluded,
    }
  end

  defp rules_from_json(data) do
    case data["rules"] do
      rules when is_list(rules) -> []
      _ -> default_rules
    end
  end
end
