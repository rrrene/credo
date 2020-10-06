defmodule Credo.Code.Name do
  @moduledoc """
  This module provides helper functions to process names of functions, module
  attributes and modules.
  """

  def last(name) when is_atom(name) do
    name
    |> to_string
    |> String.split(".")
    |> List.last()
  end

  def last(name) when is_binary(name) do
    name
    |> String.split(".")
    |> List.last()
  end

  def last(mod_list) when is_list(mod_list) do
    mod_list
    |> List.last()
    |> to_string
  end

  # Credo.Code.Name |> to_string
  # => "Elixir.Credo.Code.Name"
  def first(name) when is_atom(name) do
    name
    |> to_string
    |> String.split(".")
    |> Enum.at(1)
  end

  def first(name) when is_binary(name) do
    name
    |> String.split(".")
    |> List.first()
  end

  def first(mod_list) when is_list(mod_list) do
    mod_list
    |> List.first()
    |> to_string
  end

  def full(mod_list) when is_list(mod_list) do
    mod_list
    |> Enum.map(&full/1)
    |> Enum.join(".")
  end

  def full(name) when is_atom(name) do
    name
    |> to_string
    |> String.split(".")
    |> name_from_splitted_parts
  end

  def full(name) when is_binary(name) do
    name
  end

  def full({name, _, nil}) when is_atom(name) do
    full(name)
  end

  def full({:__aliases__, _, mod_list}) do
    full(mod_list)
  end

  def full({{:., _, [{:__aliases__, _, mod_list}, name]}, _, _}) do
    full([full(mod_list), name])
  end

  def full({:@, _, [{name, _, nil}]}) when is_atom(name) do
    "@#{name}"
  end

  def full({name, _, arguments}) when is_atom(name) and is_list(arguments) do
    arg_list = arguments |> Enum.map(&full/1) |> Enum.join(", ")

    "#{full(name)}(#{arg_list})"
  end

  def parts_count(module_name) do
    module_name
    |> String.split(".")
    |> length
  end

  def pascal_case?(name) do
    String.match?(name, ~r/^[A-Z][a-zA-Z0-9]*$/)
  end

  def split_pascal_case(name) do
    name
    |> String.replace(~r/([A-Z])/, " \\1")
    |> String.split()
  end

  def snake_case?(name) do
    String.match?(name, ~r/^[[:lower:][:digit:]\_\?\!]+$/u)
  end

  def snake_case?(name, true) do
    snake_case?(name) || snake_case_with_acronyms?(name)
  end

  def snake_case?(name, _) do
    snake_case?(name)
  end

  defp snake_case_with_acronyms?(name) do
    name
    |> String.split("_")
    |> Enum.all?(fn part ->
      String.match?(part, ~r/^([[:lower:][:digit:]]+|[[:upper:][:digit:]]+)$/u)
    end)
  end

  def no_case?(name) do
    String.match?(name, ~r/^[^a-zA-Z0-9]+$/)
  end

  defp name_from_splitted_parts(parts) when length(parts) > 1 do
    parts
    |> Enum.slice(1, length(parts))
    |> Enum.join(".")
  end

  defp name_from_splitted_parts(parts) do
    Enum.join(parts, ".")
  end
end
