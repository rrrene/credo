defmodule Credo.Check.ConfigCommentFinderTest do
  use Credo.Test.Case

  alias Credo.Check.ConfigCommentFinder

  test "it should report the correct scope" do
    source_files =
      [
        """
        defmodule OtherModule do
          # credo:disable-for-next-line
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
        """
      ]
      |> to_source_files

    config_comments =
      source_files
      |> ConfigCommentFinder.run()
      |> Enum.flat_map(fn {_filename, config_comments} -> config_comments end)

    assert Enum.find(config_comments, &(&1.line_no == 2))
    assert Enum.find(config_comments, &(&1.line_no == 7))

    assert Enum.find(config_comments, &(&1.line_no == 11 && &1.line_no_end == 15))
    assert Enum.find(config_comments, &(&1.line_no == 18 && &1.line_no_end == 21))
  end
end
