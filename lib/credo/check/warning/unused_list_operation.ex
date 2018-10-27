defmodule Credo.Check.Warning.UnusedListOperation do
  @moduledoc false

  @checkdoc """
  The result of a call to the List module's functions has to be used.

  While this is correct ...

      def sort_usernames(usernames) do
        usernames = List.flatten(usernames)

        List.sort(usernames)
      end

  ... we forgot to save the result in this example:

      def sort_usernames(usernames) do
        List.flatten(usernames)

        List.sort(usernames)
      end

  List operations never work on the variable you pass in, but return a new
  variable which has to be used somehow.
  """
  @explanation [check: @checkdoc]
  @checked_module :List
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
