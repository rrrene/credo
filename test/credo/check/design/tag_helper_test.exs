defmodule Credo.Check.Design.TagHelperTest do
  use Credo.TestHelper

  alias Credo.Check.Design.TagHelper

  test "it should NOT report expected code" do
    tags = """
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do
    assert x == x + 2
  end
end
""" |> TagHelper.tags(:TODO)

    assert [] == tags
  end

  test "it should return a tag with colon" do
    tags = """
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do # TODO: find a better name for this
    assert x == x + 2
  end
end
""" |> TagHelper.tags(:TODO)

    expected = [
        {4, "  def some_fun do # TODO: find a better name for this",
            "# TODO: find a better name for this"}
      ]

    assert expected == tags
  end

  test "it should return a tag without colon" do
    tags = """
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do # TODO find a better name for this
    assert x == x + 2
  end
end
""" |> TagHelper.tags(:TODO)

    expected = [
        {4, "  def some_fun do # TODO find a better name for this",
            "# TODO find a better name for this"}
      ]

    assert expected == tags
  end

  test "it should report a violation for all defined operations" do
    tags = """
defmodule CredoSampleModule do
  use ExUnit.Case # TODO: this is the first
  @moduledoc \"\"\"
    this is an example # TODO: and this is no actual comment
  \"\"\"

  def some_fun do # TODO this is the second
    x = ~s{also: # TODO: no comment here}
    assert 2 == x
    ?" # TODO: this is the third

    x = ~E{also: # TODO: no comment here either}

    "also: # TODO: no comment here as well"
  end
end
""" |> TagHelper.tags(:TODO)

    assert 3 == Enum.count(tags)
  end

end
