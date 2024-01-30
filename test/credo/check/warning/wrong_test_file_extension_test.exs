defmodule Credo.Check.Warning.WrongTestFileExtensionTest do
  use Credo.Test.Case

  # we can not test this check, because it uses Credo's `:files`/`:included`
  # param to only run on misnamed files :(
end
