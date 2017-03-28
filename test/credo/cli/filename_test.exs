defmodule Credo.CLI.FilenameTest do
  use ExUnit.Case
  doctest Credo.CLI.Filename

  test "the truth" do
    assert "C:/Credo/sources.ex" == Credo.CLI.Filename.remove_line_no_and_column("C:/Credo/sources.ex:39:8")
  end

  test "contains line no" do
    assert true == Credo.CLI.Filename.contains_line_no?("C:/Credo/sources.ex:39:8")
    assert true == Credo.CLI.Filename.contains_line_no?("C:/Credo/sources.ex:39")
    assert false == Credo.CLI.Filename.contains_line_no?("C:/Credo/sources.ex")
  end
end
