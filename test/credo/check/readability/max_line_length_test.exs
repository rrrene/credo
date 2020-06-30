defmodule Credo.Check.Readability.MaxLineLengthTest do
  use Credo.Test.Case

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
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for URLs" do
    """
    def fun do
      # Based on https://github.com/rrrene/credo/blob/7dec9aecdd21ef33fdc20cc4ac6c94efb4bcddc3/lib/credo.ex#L4
      nil
    end
    """
    |> to_source_file
    |> run_check(@described_check, max_length: 80)
    |> refute_issues()
  end

  test "it should NOT report expected code /2" do
    """
    defmacro some_macro(type) do
      quote do
        fragment("CASE
          WHEN
            (? = 'some_text'
            OR ? = 'some_text_2'
            OR ? = 'some_text_3')
          THEN '1'
          ELSE '2'
        END", unquote(type), unquote(type), unquote(type))
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code if function defintions are excluded" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun({atom, meta, arguments} = ast, issues, source_file, max_complexity) do
        assert 1 + 1 == 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, max_length: 80, ignore_definitions: true)
    |> refute_issues()
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
    """
    |> to_source_file
    |> run_check(@described_check, max_length: 80, ignore_specs: true)
    |> refute_issues()
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
    """
    |> to_source_file
    |> run_check(@described_check, max_length: 80, ignore_strings: true)
    |> refute_issues()
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
    """
    |> to_source_file
    |> run_check(@described_check, max_length: 80, ignore_strings: true)
    |> refute_issues()
  end

  test "it should NOT report a violation with exec" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        assert 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 == 2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, max_length: 90)
    |> refute_issues()
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
    """
    |> to_source_file
    |> run_check(@described_check, max_length: 80)
    |> assert_issue(fn issue ->
      assert 81 == issue.column
      assert "2" == issue.trigger
    end)
  end

  test "it should report a violation /2" do
    """
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        assert "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" <> "1" == "2"
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, max_length: 80)
    |> assert_issue(fn issue ->
      assert 81 == issue.column
      assert issue.message =~ ~r/max is 80, was 112/
    end)
  end

  test "it should report a violation /3" do
    """
    def fun do
      # Based on https://github.com/rrrene/credo/blob/7dec9aecdd21ef33fdc20cc4ac6c94efb4bcddc3/lib/credo.ex#L4
      nil
    end
    """
    |> to_source_file
    |> run_check(@described_check, max_length: 80, ignore_urls: false)
    |> assert_issue()
  end
end
