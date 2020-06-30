defmodule Credo.CLI.Output.UI do
  @moduledoc """
  This module provides functions used to create the UI.

      >>> alias Credo.CLI.Output.UI
      >>> UI.puts "This is a test."
      This is a test.
      nil

      >>> alias Credo.CLI.Output.UI
      >>> UI.warn "This is a warning."
      This is a warning.
      nil

  """

  @edge "┃"
  @ellipsis "…"
  @shell_service Credo.CLI.Output.Shell

  if Mix.env() == :test do
    def puts, do: nil
    def puts(_), do: nil
    def puts(_, color) when is_atom(color), do: nil

    def warn(_), do: nil
  else
    defdelegate puts, to: @shell_service
    defdelegate puts(v), to: @shell_service

    def puts(v, color) when is_atom(color) do
      @shell_service.puts([color, v])
    end

    defdelegate warn(v), to: @shell_service
  end

  def edge(color, indent \\ 2) when is_integer(indent) do
    [:reset, color, @edge |> String.pad_trailing(indent)]
  end

  @doc "Returns the edge (`┃`) which is used in much of Credo's output as a binary."
  def edge, do: @edge

  def use_colors(exec) do
    @shell_service.use_colors(exec.color)

    exec
  end

  def puts_edge(color, indent \\ 2) when is_integer(indent) do
    color
    |> edge(indent)
    |> puts
  end

  def wrap_at(text, number) do
    "(?:((?>.{1,#{number}}(?:(?<=[^\\S\\r\\n])[^\\S\\r\\n]?|(?=\\r?\\n)|$|[^\\S\\r\\n]))|.{1,#{
      number
    }})(?:\\r?\\n)?|(?:\\r?\\n|$))"
    |> Regex.compile!("u")
    |> Regex.scan(text)
    |> Enum.map(&List.first/1)
    |> List.delete_at(-1)
  end

  @doc """
  Truncate a line to fit within a specified maximum length.
  Truncation is indicated by a trailing ellipsis (…), and you can override this
  using an optional third argument.

      iex> Credo.CLI.Output.UI.truncate(nil, 7)
      ""
      iex> Credo.CLI.Output.UI.truncate("  7 chars\\n", 7)
      "  7 ch…"
      iex> Credo.CLI.Output.UI.truncate("  more than 7\\n", 7)
      "  more…"
      iex> Credo.CLI.Output.UI.truncate("  more than 7\\n", 7, " ...")
      "  m ..."
  """
  def truncate(line, max_length) when max_length <= 0 or is_nil(line), do: ""

  def truncate(line, max_length) when max_length > 0 do
    truncate(line, max_length, @ellipsis)
  end

  def truncate(_line, max_length, _ellipsis) when max_length <= 0, do: ""

  def truncate(line, max_length, ellipsis) when max_length > 0 do
    cond do
      String.length(line) <= max_length ->
        line

      String.length(ellipsis) >= max_length ->
        ellipsis

      true ->
        chars_to_display = max_length - String.length(ellipsis)
        String.slice(line, 0, chars_to_display) <> ellipsis
    end
  end
end
