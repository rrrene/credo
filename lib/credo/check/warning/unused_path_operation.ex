defmodule Credo.Check.Warning.UnusedPathOperation do
  @moduledoc """
  The result of a call to the Path module's functions has to be used.

  # TODO: write example

  Path operations never work on the variable you pass in, but return a new
  variable which has to be used somehow.
  """

  @explanation [check: @moduledoc]
  @checked_module :Path
  @funs_with_return_value nil

  use Credo.Check, base_priority: :high

  alias Credo.Check.Warning.UnusedOperation

  def run(source_file, params \\ []) do
    UnusedOperation.run(
      source_file,
      params,
      @checked_module,
      @funs_with_return_value,
      &format_issue/2
    )
  end
end
