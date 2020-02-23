defmodule Credo.CLITest do
  use Credo.Test.Case

  @moduletag slow: :integration

  doctest Credo.CLI
end
