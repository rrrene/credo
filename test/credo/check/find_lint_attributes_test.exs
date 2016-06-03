defmodule Credo.Check.FindLintAttributesTest do
  use Credo.TestHelper

  use Credo.TestHelper

  alias Credo.Check.FindLintAttributes

  test "it should report the correct scope" do
    source_file = """
defmodule OtherModule do
  @lint false
  defmacro foo do
    {:ok} = File.read
  end

  @lint false
  some_macro do
  end

  @lint false
  @doc false
  defp bar do
    :ok
  end
end
""" |> to_source_file

    source_file2 = FindLintAttributes.find_and_set_in_source_file(source_file)
    lint_attributes = source_file2.lint_attributes

    assert lint_attributes |> Enum.find(&(&1.scope == "OtherModule.foo"))
    assert lint_attributes |> Enum.find(&(&1.scope == "OtherModule"))
    assert lint_attributes |> Enum.find(&(&1.scope == "OtherModule.bar"))
  end
end
