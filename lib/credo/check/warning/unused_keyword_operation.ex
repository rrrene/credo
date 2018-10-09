defmodule Credo.Check.Warning.UnusedKeywordOperation do
  @moduledoc """
  The result of a call to the Keyword module's functions has to be used.

  # TODO: write example

  Keyword operations never work on the variable you pass in, but return a new
  variable which has to be used somehow.
  """

  use Credo.Check, base_priority: :high

  alias Credo.Check.Warning.UnusedOperation

  @explanation [check: @moduledoc]
  @checked_module :Keyword

  def run(source_file, params \\ []) do
    UnusedOperation.run(source_file, params, @checked_module, [], &format_issue/2)
  end
end
