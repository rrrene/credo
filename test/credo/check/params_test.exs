defmodule Credo.Check.ParamsTest do
  use Credo.Test.Case

  # This is defined here so the doctest for `get/3` can use this module
  defmodule SamepleCheck do
    def param_defaults do
      [foo: "bar"]
    end
  end

  doctest Credo.Check.Params
end
