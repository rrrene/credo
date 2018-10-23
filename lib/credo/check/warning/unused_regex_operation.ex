defmodule Credo.Check.Warning.UnusedRegexOperation do
  @moduledoc """
  The result of a call to the Regex module's functions has to be used.

  # TODO: write example

  Regex operations never work on the variable you pass in, but return a new
  variable which has to be used somehow.
  """

  @explanation [check: @moduledoc]
  @checked_module :Regex

  use Credo.Check, base_priority: :high

  alias Credo.Check.Warning.UnusedOperation

  def run(source_file, params \\ []) do
    UnusedOperation.run(source_file, params, @checked_module, [], &format_issue/2)
  end
end
