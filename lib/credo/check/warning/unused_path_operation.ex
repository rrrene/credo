defmodule Credo.Check.Warning.UnusedPathOperation do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: """
      The result of a call to the Path module's functions has to be used.

      While this is correct ...

          def read_from_cwd(filename) do
            filename = Path.join(cwd, filename)

            File.read(filename)
          end

      ... we forgot to save the result in this example:

          def read_from_cwd(filename) do
            Path.join(cwd, filename)

            File.read(filename)
          end

      Path operations never work on the variable you pass in, but return a new
      variable which has to be used somehow.
      """
    ]

  alias Credo.Check.Warning.UnusedOperation

  @checked_module :Path
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
