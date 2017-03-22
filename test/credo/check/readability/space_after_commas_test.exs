defmodule Credo.Check.Readability.SpaceAfterCommasTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.SpaceAfterCommas

  #
  # cases NOT raising issues
  #

  test "it should NOT report when commas have spaces" do
"""
defmodule CredoSampleModule do
  alias Project.{Sample, Other}
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report when commas have newlines" do
"""
defmodule CredoSampleModule do
    defstruct foo: nil,
              bar: nil
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report when commas are not followed by spaces" do
"""
defmodule CredoSampleModule do
  alias Project.{Sample,Other}
end
""" |> to_source_file
    |> assert_issue(@described_check, fn(issue) ->
        assert 24 == issue.column
        assert ",O" ==  issue.trigger
      end)
  end

  test "it should report when there are many commas not followed by spaces" do
"""
defmodule CredoSampleModule do
  @attribute [1,2,3,4,5]
end
""" |> to_source_file
    |> assert_issues(@described_check, fn(issues) ->
        assert 4 == Enum.count(issues)
        assert [16, 18, 20, 22] == Enum.map(issues, &(&1.column))
        assert [",2", ",3", ",4", ",5"] == Enum.map(issues, &(&1.trigger))
    end)
  end
end
