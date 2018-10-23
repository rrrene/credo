defmodule Credo.Check.Warning.UnusedTupleOperation do
  @moduledoc """
  The result of a call to the Tuple module's functions has to be used.

  # TODO: write example

  Tuple operations never work on the variable you pass in, but return a new
  variable which has to be used somehow.
  """

  @explanation [check: @moduledoc]
  @checked_module :Tuple
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
