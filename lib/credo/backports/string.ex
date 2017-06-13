defmodule Credo.Backports.String do
  @moduledoc """
  This module provides functions which are not supported in all Elixir versions
  supported by Credo.
  """

  @doc """
  Removes white-space at the beginning and end of the given `string`.

      iex> Credo.Backports.String.trim(" credo  ")
      "credo"

      iex> Credo.Backports.String.trim("credo  ")
      "credo"

      iex> Credo.Backports.String.trim(" credo")
      "credo"

      iex> Credo.Backports.String.trim("credo")
      "credo"

  """
  def trim(string)

  if Version.match?(System.version, "< 1.3.0") do
    def trim(string), do: String.strip(string)
  else
    def trim(string), do: String.trim(string)
  end


  @doc """
  Converts the given `string` to a character list.

      iex> Credo.Backports.String.to_charlist("credo")
      'credo'

  """
  def to_charlist(string)

  if Version.match?(System.version, "< 1.3.0") do
    def to_charlist(string), do: String.to_char_list(string)
  else
    def to_charlist(string), do: String.to_charlist(string)
  end


  @doc """
  Returns a new string of length `count` with `string` right justified and
  padded with spaces.

      iex> Credo.Backports.String.pad_leading("credo", 8)
      "   credo"

      iex> Credo.Backports.String.pad_leading("credo", 4)
      "credo"

  """
  def pad_leading(string, count)

  if Version.match?(System.version, "< 1.3.0") do
    def pad_leading(string, count), do: String.rjust(string, count)
  else
    def pad_leading(string, count), do: String.pad_leading(string, count)
  end


  @doc """
  Returns a new string of length `count` with `string` left justified and
  padded with spaces.

      iex> Credo.Backports.String.pad_trailing("credo", 8)
      "credo   "

  """
  def pad_trailing(string, count)

  if Version.match?(System.version, "< 1.3.0") do
    def pad_trailing(string, count), do: String.ljust(string, count)
  else
    def pad_trailing(string, count), do: String.pad_trailing(string, count)
  end

end
