defmodule Credo.Severity do
  @moduledoc false

  def default_value, do: 1

  def compute(_, 0), do: 65_536
  def compute(value, max_value), do: value / max_value
end
