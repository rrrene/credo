defmodule Credo.Check.Readability.MaxLineLengthTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.MaxLineLength

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do
    assert 1 + 1 == 2
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report expected code if function defintions are excluded" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun({atom, meta, arguments} = ast, issues, source_file, max_complexity) do
    assert 1 + 1 == 2
  end
end
""" |> to_source_file
    |> refute_issues(@described_check, ignore_definitions: true)
  end

  test "it should NOT report expected code if @spec's are excluded" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  @spec some_fun(binary, binary, binary, binary, binary, binary, binary, binary, binary)
  def some_fun(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) do
    assert 1 + 1 == 2
  end
end
""" |> to_source_file
    |> refute_issues(@described_check, ignore_specs: true)
  end

  test "it should NOT report a violation if strings are excluded" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do
    IO.puts 1
    "long string, right? 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 == 2"
    IO.puts 2
  end
end
""" |> to_source_file
    |> refute_issues(@described_check, ignore_strings: true)
  end

  test "it should NOT report a violation if strings are excluded for heredocs" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do
    IO.puts 1
    \"\"\"
    long string, right? 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 == 2
    \"\"\"
    IO.puts 2
  end
end
""" |> to_source_file
    |> refute_issues(@described_check, ignore_strings: true)
  end

  test "it should NOT report a violation with exec" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do
    assert 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 == 2
  end
end
""" |> to_source_file
    |> refute_issues(@described_check, max_length: 90)
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do
    assert 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 == 2
  end
end
""" |> to_source_file
    |> assert_issue(@described_check, fn(issue) ->
        assert 81 == issue.column
        assert "2" == issue.trigger
      end)
  end

  test "it should report a violation with strings and code" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case
  def some_fun do
    assert "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" == "2"
  end
end
"""
    |> to_source_file
    |> assert_issue(@described_check, max_length: 100)
  end

  test "it should report a violation with strings and code again" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case
  def some_fun do
    assert "a really long line a really long line a really long line a really long line"
  end
end
"""
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation with strings and code again again" do
"""
defmodule CredoSampleModule do
  def some_fun do
    blah = ~s{
        a really long line a really long line a really long line a really long line
    }
  end
end
"""
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation with strings and code again again again" do
"""
defmodule CredoSampleModule do
  def some_fun do
    blah = \"\"\"
        a really long line a really long line a really long line a really long line
    \"\"\"
  end
end
"""
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should NOT report a violation with strings on their own line" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case
  def some_fun do
    assert
      "a really long line a really long line a really long line a really long line"
  end
end
"""
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report a violation with strings on their own line again" do
"""
defmodule CredoSampleModule do
  def some_fun do
    blah =
    ~s{
        a really long line a really long line a really long line a really long line
    }
  end
end
"""
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report a violation with strings on their own line again again" do
"""
defmodule CredoSampleModule do
  def some_fun do
    blah =
    \"\"\"
        a really long line a really long line a really long line a really long line
    \"\"\"
  end
end
"""
    |> to_source_file
    |> refute_issues(@described_check)
  end

end
