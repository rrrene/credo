defmodule Credo.Check.Warning.UnusedKeywordOperation do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: """
      The result of a call to the Keyword module's functions has to be used.

      While this is correct ...

          def clean_and_verify_options!(keywords) do
            keywords = Keyword.delete(keywords, :debug)

            if Enum.length(keywords) == 0, do: raise "OMG!!!1"

            keywords
          end

      ... we forgot to save the result in this example:

          def clean_and_verify_options!(keywords) do
            Keyword.delete(keywords, :debug)

            if Enum.length(keywords) == 0, do: raise "OMG!!!1"

            keywords
          end

      Keyword operations never work on the variable you pass in, but return a new
      variable which has to be used somehow.
      """
    ]

  alias Credo.Check.Warning.UnusedOperation

  @checked_module :Keyword
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
