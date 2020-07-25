defmodule Credo.CLI.Filename do
  @moduledoc """
  This module can be used to handle filenames given at the command line.
  """

  @doc """
  Returns `true` if a given `filename` contains a pos_suffix.

      iex> Credo.CLI.Filename.contains_line_no?("lib/credo/sources.ex:39:8")
      true

      iex> Credo.CLI.Filename.contains_line_no?("lib/credo/sources.ex:39")
      true

      iex> Credo.CLI.Filename.contains_line_no?("lib/credo/sources.ex")
      false
  """
  def contains_line_no?(nil), do: false

  def contains_line_no?(filename) do
    count =
      filename
      |> String.split(":")
      |> Enum.count()

    if windows_path?(filename) do
      count == 3 || count == 4
    else
      count == 2 || count == 3
    end
  end

  @doc """
  Returns a suffix for a filename, which contains a line and column value.

      iex> Credo.CLI.Filename.pos_suffix(39, 8)
      ":39:8"

      iex> Credo.CLI.Filename.pos_suffix(39, nil)
      ":39"

  These are used in this way: lib/credo/sources.ex:39:8
  """
  def pos_suffix(nil, nil), do: ""
  def pos_suffix(line_no, nil), do: ":#{line_no}"
  def pos_suffix(line_no, column), do: ":#{line_no}:#{column}"

  @doc """
  Removes the pos_suffix for a filename.

      iex> Credo.CLI.Filename.remove_line_no_and_column("lib/credo/sources.ex:39:8")
      "lib/credo/sources.ex"
  """
  def remove_line_no_and_column(filename) do
    filename
    |> String.split(":")
    |> remove_line_no_and_column(windows_path?(filename))
  end

  defp remove_line_no_and_column(parts, true) do
    Enum.at(parts, 0) <> ":" <> Enum.at(parts, 1)
  end

  defp remove_line_no_and_column(parts, false) do
    List.first(parts)
  end

  defp windows_path?(path) do
    String.contains?(path, ":\/")
  end

  @doc """
  Adds a pos_suffix to a filename.

      iex> Credo.CLI.Filename.with("test/file.exs", %{:line_no => 1, :column => 2})
      "test/file.exs:1:2"
  """
  def with(filename, opts) do
    filename <> pos_suffix(opts[:line_no], opts[:column])
  end
end
