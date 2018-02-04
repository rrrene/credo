defmodule Credo.CLI.Command.Info do
  use Credo.CLI.Command

  alias Credo.CLI.Output.UI

  @shortdoc "Show useful debug information"
  @moduledoc @shortdoc

  @doc false
  def call(exec, _opts) do
    """
    System:
      Credo: #{Credo.version()}
      Elixir: #{System.version()}
      Erlang: #{System.otp_release()}
    """
    |> String.trim()
    |> UI.puts()

    exec
  end
end
