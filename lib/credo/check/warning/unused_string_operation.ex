defmodule Credo.Check.Warning.UnusedStringOperation do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: """
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
    ]

  alias Credo.Check.Warning.UnusedFunctionReturnHelper
  alias Credo.Check.Warning.UnusedOperation

  @checked_module :String
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

  def autofix(file, _issue) do
    {_, quoted} = Credo.Code.ast(file)
    source_file = SourceFile.parse(file, "nofile")

    unused_calls =
      UnusedFunctionReturnHelper.find_unused_calls(
        source_file,
        [],
        [@checked_module],
        @funs_with_return_value
      )

    modified =
      quoted
      |> Macro.prewalk(&do_autofix(&1, unused_calls))
      |> Macro.to_string()
      |> :"Elixir.Code".format_string!()
      |> to_string()

    "#{modified}\n"
  end

  defp do_autofix({:__block__, meta, [{:|>, _pipe_meta, pipe_args} | tail] = args}, unused_calls) do
    args =
      if List.last(pipe_args) in unused_calls do
        [hd(pipe_args) | tail]
      else
        args
      end

    {:__block__, meta, args}
  end

  defp do_autofix({:__block__, meta, args}, unused_calls) do
    {:__block__, meta, Enum.reject(args, & &1 in unused_calls)}
  end

  defp do_autofix({:do, node}, unused_calls) do
    {:do, do_autofix(node, unused_calls)}
  end

  defp do_autofix(ast, _), do: ast
end
