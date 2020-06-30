defmodule Credo.Check.Warning.UnusedFileOperation do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: """
      The result of a call to the File module's functions has to be used.

      While this is correct ...

          def read_from_cwd(filename) do
            # TODO: use Path.join/2
            filename = File.cwd!() <> "/" <> filename

            File.read(filename)
          end

      ... we forgot to save the result in this example:

          def read_from_cwd(filename) do
            File.cwd!() <> "/" <> filename

            File.read(filename)
          end

      Since Elixir variables are immutable, many File operations don't work on the
      variable you pass in, but return a new variable which has to be used somehow.
      """
    ]

  alias Credo.Check.Warning.UnusedOperation

  @checked_module :File
  @funs_with_return_value ~w(cwd cwd! dir? exists? read read! regular? stat stat!)a

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
