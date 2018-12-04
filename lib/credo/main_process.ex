defmodule Credo.MainProcess do
  @moduledoc false

  # This module defines all Tasks which make up the execution of Credo.

  use Credo.Execution.ProcessDefinition

  alias Credo.Execution.Task

  activity :parse_cli_options do
    run Task.ParseOptions
  end

  activity :validate_cli_options do
    run Task.ValidateOptions
  end

  activity :convert_cli_options_to_config do
    run Task.ConvertCLIOptionsToConfig
  end

  activity :determine_command do
    run Task.DetermineCommand
  end

  activity :set_default_command do
    run Task.SetDefaultCommand
  end

  activity :resolve_config do
    run Task.UseColors
    run Task.RequireRequires
  end

  activity :validate_config do
    run Task.ValidateConfig
  end

  activity :run_command do
    run Task.RunCommand
  end

  activity :halt_execution do
    run Task.AssignExitStatusForIssues
  end
end
