defmodule Credo.Check.Readability.OnePipePerLineTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.OnePipePerLine

  #
  # cases NOT raising issues
  #

  test "it should NOT report the expected code" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        1
        |> Integer.to_string()
        |> String.to_integer()
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation that includes rejected module attrs" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        1 |> Integer.to_string() |> String.to_integer()
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 5, trigger: "|>"})
  end

  test "it should report multiple violations when having multiples pipes" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        "1" |> String.to_integer() |> Integer.to_string()
        1 |> Integer.to_string() |> String.to_integer()
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues(2)
  end

  test "it should report multiple violations when having multiples pipes /2" do
    ~S'''
    defmodule CredoSampleModule do
      use ExUnit.Case

      def some_fun do
        assert map == ast |> Macro.postwalk([], &{&1, [&1 | &2]}) |> elem(1) |> Enum.reverse()
        {var |> Atom.to_string() |> string() |> color_doc(:variable, state.inspect_opts), state}
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues(2)
  end
end
