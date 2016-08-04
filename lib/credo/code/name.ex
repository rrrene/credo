defmodule Credo.Code.Name do
  @moduledoc """
  This module provides helper functions to process names of functions, module
  attributes and modules.
  """

  def last(name) when is_atom(name) do
    name |> to_string |> String.split(".") |> List.last
  end
  def last(name) when is_binary(name) do
    name |> String.split(".") |> List.last
  end
  def last(mod_list) when is_list(mod_list) do
    mod_list |> List.last |> to_string
  end

  def first(name) when is_atom(name) do
    name |> to_string |> String.split(".") |> List.first
  end
  def first(name) when is_binary(name) do
    name |> String.split(".") |> List.first
  end
  def first(mod_list) when is_list(mod_list) do
    mod_list |> List.first |> to_string
  end

  def full_name({:__aliases__, _, mod_list}) do
    mod_list |> full_name
  end
  def full_name(mod_list) when is_list(mod_list) do
    mod_list
    |> Enum.map(&full_name/1)
    |> Enum.join(".")
  end
  def full_name({name, _, nil}) when is_atom(name) do
    name |> full_name
  end
  def full_name(name) when is_binary(name) or is_atom(name) do
    name
  end

  def parts_count(module_name) do
    module_name
    |> String.split(".")
    |> length
  end

  def pascal_case?(name) do
    name |> String.match?(~r/^[A-Z][a-zA-Z0-9]*$/)
  end

  def split_pascal_case(name) do
    name |> String.replace(~r/([A-Z])/, " \\1") |> String.split
  end

  def snake_case?(name) do
    name |> String.match?(~r/^[a-z0-9\_\?\!]+$/)
  end
end
