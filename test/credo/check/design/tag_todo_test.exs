defmodule Credo.Check.Design.TagTODOTest do
  use Credo.TestHelper

  @described_check Credo.Check.Design.TagTODO

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do
    assert x == x + 2
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report an issue" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case # FIXME: this should not appear in the TODO test

  # TODO: this should not appear in the # TODO test

  def some_fun do
    assert x == x + 2
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report an issue at the end of a line w/o space" do
"""
defmodule CredoSampleModule do
  def some_fun do
    Repo.preload(:comments)# TODO blah blah
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report an issue when lower case" do
"""
defmodule CredoSampleModule do
  def some_fun do
    # todo blah blah
    Repo.preload(:comments)
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a couple of issues" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case # TODO: this is the first
  @moduledoc \"\"\"
    this is an example # TODO: and this is no actual comment
  \"\"\"

  def some_fun do # TODO this is the second
    x = ~s{also: # TODO: no comment here}
    assert 2 == x
    ?" # TODO: this is the third

    "also: # TODO: no comment here as well"
  end
end
""" |> to_source_file
    |> assert_issues(@described_check, fn(issues) ->
        assert 3 == Enum.count(issues)
      end)
  end

end
