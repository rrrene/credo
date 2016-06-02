defmodule Credo.Severity do
  @moduledoc """
  Severity describes how strongly a check has failed and produced an issue.

  The default value is 1 and values only take values higher than that.
  """

  def default_value, do: 1

  def compute(_, 0), do: 65_536
  def compute(value, max_value), do: value / max_value
end
