defmodule Credo.Check.Consistency.SpaceInParenthesesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Consistency.SpaceInParentheses

  @without_spaces ~S'''
  defmodule Credo.Sample1 do
    @default_sources_glob ~w(** *.{ex,exs})
    @username_regex ~r/^[A-z0-9 ]+$/
    @options [foo: 1, bar: 2, ]

    defmodule InlineModule do
      def foobar do
        {:ok} = File.read(filename)

        parse_code(t, {:some_tuple, 1})
        parse_code(t, acc <> ~s(\"\"\"))
      end
      defp count([], acc), do: acc
      defp count([?( | t], acc), do: count(t, acc + 1)
      defp count([?) | t], acc), do: count(t, acc - 1)

      def foo(a) do
        "#{a} #{a}"
        :"b_#{a}_"
      end

      def bar do
        " )"
      end
    end

    defmodule Foo do
      def bar(a, b) do
        # The next line is the one the error is incorrectly reported against
        if (a + b) / 100 > threshold(), do: :high, else: :low
      end

      def threshold, do: 50
    end

    def credo_test do
      sh_snip = 'if [ ! -d /somedir ] ...'
      foo = 'and here are some ( parenthesis )'
    end
  end
  '''
  @with_spaces ~S'''
  defmodule Credo.Sample2 do
    defmodule InlineModule do
      def foobar do
        { :ok } = File.read( filename )
      end
    end
  end
  '''
  @with_spaces2 ~S'''
  defmodule OtherModule3 do
    defmacro foo do
        { :ok } = File.read( filename )
    end

    defp bar do
      :ok
    end
  end
  '''
  @with_spaces_empty_params1 ~S'''
  defmodule Credo.Sample2 do
    defmodule InlineModule do
      def foobar do
        { :ok } = File.read( %{} )
      end
    end
  end
  '''
  @with_spaces_empty_params2 ~S'''
  defmodule Credo.Sample2 do
    defmodule InlineModule do
      def foobar do
        { :ok } = File.read( [] )
      end
    end
  end
  '''
  @with_and_without_spaces ~S'''
  defmodule OtherModule3 do
    defmacro foo do
      { :ok } = File.read( filename )
    end

    defp bar do
      {:ok, :test}
    end
  end
  '''

  #
  # cases NOT raising issues
  #

  test "it should NOT report the correct result " do
    [
      @without_spaces
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report the correct result 1" do
    [
      @with_spaces,
      @with_spaces2
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report with config on empty params" do
    [
      @with_spaces_empty_params1,
      @with_spaces_empty_params2
    ]
    |> to_source_files()
    |> run_check(@described_check, allow_empty_enums: true)
    |> refute_issues()
  end

  test "it should NOT report with without_spaces" do
    [
      ~S'''
      defmodule Credo.Test.IntegrationTest do
        def run(argv) do
          if System.get_env("DEBUG") do
            {suffix, remainder} = Enum.split_while(remainder, &(&1 != ?\n))
          end
        end
      end

      '''
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report the correct result 2" do
    [
      @without_spaces,
      @with_spaces,
      @with_spaces2
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report the correct result 3" do
    [
      @with_and_without_spaces
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issues(2)
    |> assert_issues_match([
      %{line_no: 7, trigger: "{"},
      %{line_no: 7, trigger: "}"}
    ])
  end

  test "it should report with no config on empty map" do
    [
      @with_spaces_empty_params1
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 4, trigger: "%{}"})
  end

  test "it should report with no config on empty array" do
    [
      @with_spaces_empty_params2
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 4, trigger: "[]"})
  end
end
