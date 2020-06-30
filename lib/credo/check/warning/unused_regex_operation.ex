defmodule Credo.Check.Warning.UnusedRegexOperation do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: """
      The result of a call to the Regex module's functions has to be used.

      While this is correct ...

          def extract_username_and_salute(regex, string) do
            [string] = Regex.run(regex, string)

            "Hi #\{string}"
          end

      ... we forgot to save the downcased username in this example:

          def extract_username_and_salute(regex, string) do
            Regex.run(regex, string)

            "Hi #\{string}"
          end

      Regex operations never work on the variable you pass in, but return a new
      variable which has to be used somehow.
      """
    ]

  alias Credo.Check.Warning.UnusedOperation

  @checked_module :Regex
  @funs_with_return_value nil

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    UnusedOperation.run(
      source_file,
      params,
      @checked_module,
      @funs_with_return_value,
      &format_issue/2
    )
  end
end
