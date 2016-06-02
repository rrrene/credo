defmodule Credo.Check.PropertyValue do
  def for(value, meta_info), do: {__MODULE__, value, meta_info}

  def get({__MODULE__, value, _}), do: value
  def get(list) when is_list(list), do: list |> Enum.map(&get/1)
  def get(value), do: value

  def meta(tuple, key) do
    m = meta(tuple)
    m[key]
  end
  def meta({__MODULE__, _, value}), do: value
  def meta(list) when is_list(list), do: list |> Enum.map(&meta/1)
end
