defmodule Credo.Check.Warning.UnusedStringOperation do
  @moduledoc false

  @checkdoc """
  The result of a call to the String module's functions has to be used.

  While this is correct ...

      def salutation(username) do
        username = String.downcase(username)

        "Hi #\{username}"
      end

  ... we forgot to save the downcased username in this example:

      # This is bad because it does not modify the username variable!

      def salutation(username) do
        String.downcase(username)

        "Hi #\{username}"
      end

  Since Elixir variables are immutable, String operations never work on the
  variable you pass in, but return a new variable which has to be used somehow.
  """
  @explanation [check: @checkdoc]
  @checked_module :String
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
