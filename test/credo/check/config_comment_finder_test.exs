defmodule Credo.Check.ConfigCommentFinderTest do
  use Credo.TestHelper

  use Credo.TestHelper

  alias Credo.Check.ConfigCommentFinder

  test "it should report the correct scope" do

    source_file = """
defmodule OtherModule do
  # credo:disable-next-line
  defmacro fooBarCool do
    {:ok} = File.read
  end

  # credo:disable-for-this-file
  some_macro do
  end

  # credo:disable-for-lines:4
  @doc false
  defp bar do
    :ok
  end

  @doc false
  defp baz do
    :ok
  end
  # credo:disable-for-lines:-3 Credo.Check.Readability.MaxLineLength
end
""" |> to_source_file

    source_file2 = ConfigCommentFinder.find_and_set_in_source_file(source_file)
    config_comments = source_file2.config_comments

    assert config_comments |> Enum.find(&(&1.line_no == 2))
    assert config_comments |> Enum.find(&(&1.line_no == 7))
    assert config_comments |> Enum.find(&(&1.line_no == 11 && &1.line_no_end == 15))
    assert config_comments |> Enum.find(&(&1.line_no == 18 && &1.line_no_end == 21))
  end
end
