defmodule Credo.Check.Warning.UnusedPathOperationTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.UnusedPathOperation

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Path.join(parameter1) + parameter2
      end
    end

    defmodule CredoExample do
      def error do
        module().call(Path.join("~", "foo"))

        "something"
      end

      def no_error(:one) do
        call(Path.join("~", "foo"))

        "something"
      end

      def no_error(:two) do
        module().call(Path.join("~", "foo"))
      end

      defp call(path) do
        IO.puts path
      end

      defp module do
        CredoExample
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when result is piped" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Path.join(parameter1)
        |>  some_where

        parameter1
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when end of pipe AND return value" do
    """
    defmodule CredoSampleModule do
    def some_function(parameter1, parameter2) do
      parameter1 + parameter2
      |> Path.join(parameter1)
    end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when inside of pipe" do
    """
    defmodule CredoSampleModule do
    def some_function(parameter1, parameter2) do
      parameter1 + parameter2
      |> Path.join(parameter1)
      |> some_func_who_knows_what_it_does

      :ok
    end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when inside an assignment" do
    """
    defmodule CredoSampleModule do
    def some_function(parameter1, parameter2) do
      offset = Path.relative(line)

      parameter1 + parameter2 + offset
    end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when inside a condition" do
    """
    defmodule CredoSampleModule do
    def some_function(parameter1, parameter2) do
      if Path.relative(x1) == Path.relative(x2) do
        cond do
          Path.relative(x3) == "" -> IO.puts("1")
          Path.relative(x) == 15 -> IO.puts("2")
          Path.join(x3, 1) == "b" -> IO.puts("2")
        end
      else
        case Path.relative(x3) do
          0 -> true
          1 -> false
          _ -> something
        end
      end
      unless Path.relative(x4) == "" do
        IO.puts "empty"
      end

      parameter1 + parameter2 + offset
    end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when inside a quote" do
    """
    defmodule CredoSampleModule do
    defp category_body(nil) do
      quote do
        __MODULE__
        |> Module.split
        |> Path.join(2)
      end
    end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when inside of assignment" do
    """
    defmodule CredoSampleModule do
    defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
      pos =
        pos_string(issue.line_no, issue.column)

      [
        Output.issue_color(issue), "┃ ",
        Output.check_tag(check), " ", priority |> Output.priority_arrow,
        :normal, :white, " ", message,
      ]
      |> IO.ANSI.format
      |> IO.puts

      if issue.column do
        offset = Path.count(line)
        [
            Path.join(x, " "), :faint, Path.join(w, ","),
        ]
        |> IO.puts
      end

      [Output.issue_color(issue), :faint, "┃ "]
      |> IO.ANSI.format
      |> IO.puts
    end

    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when call is buried in else block but is the last call" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          IO.puts "."
        else
          [:this_actually_might_return, Path.join(w, ","), :ok] # THIS is not the last_call!
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when call is buried in else block and is not the last call, but the result is assigned to a variable" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        result =
          if issue.column do
            IO.puts "."
          else
            [:this_goes_nowhere, Path.join(w, ",")]
          end

        IO.puts "8"
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when buried in :if, :when and :fn 2" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          IO.puts "."
        else
          case check do
            true -> false
            _ ->
              Path.reduce(arr, fn(w) ->
                [:this_might_return, Path.join(w, ",")]
              end)
          end
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when :for and :case" do
    """
    defmodule CredoSampleModule do
      defp convert_parsers(parsers) do
        for parser <- parsers do
          case Atom.to_string(parser) do
            "Elixir." <> _ -> parser
            reference      -> Path.join(reference)
          end
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when part of a function call" do
    """
    defmodule CredoSampleModule do
      defp convert_parsers(parsers) do
        for parser <- parsers do
          case Atom.to_string(parser) do
            "Elixir." <> _ -> parser
            reference      -> Module.concat(Plug.Parsers, Path.join(reference))
          end
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when :for and :case 2" do
    """
    defmodule CredoSampleModule do
      defp convert_parsers(parsers) do
        for x <- Path.flat_map(bin, &(&1.blob)), x != "", do: x
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when :for 2" do
    """
    defmodule CredoSampleModule do
      defp sum(_) do
        for x <- [1..3, 5..10], sum=Path.sum(x), do: sum
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in :after block" do
    """
      defp my_function(fun, opts) do
        try do
          :fprof.analyse(
            dest: analyse_dest,
            totals: true,
            details: Keyword.get(opts, :details, false),
            callers: Keyword.get(opts, :callers, false),
            sort: sorting
          )
        else
          :ok ->
            {_in, analysis_output} = StringIO.contents(analyse_dest)
            Path.count(analysis_output)
        after
          StringIO.close(analyse_dest)
        end
      end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in function call" do
    """
      def my_function(url) when is_binary(url) do
        if info.userinfo do
          destructure [username, password], Path.join(info.userinfo, ":")
        end

        Path.reject(opts, fn {_k, v} -> is_nil(v) end)
      end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in function call 2" do
    """
      defp print_process(pid_atom, count, own) do
        IO.puts([?", Path.join(own, "-")])
        IO.write format_item(Path.join(path, item), Path.take(item, width))
        print_row(["s", "B", "s", ".3f", "s"], [count, "", own, ""])
      end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in list that is returned" do
    """
    defp indent_line(str, indentation, with \\\\ " ") do
      [Path.join(with, indentation), str]
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report a violation when buried in :if, :when and :fn" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          IO.puts "."
        else
          case check do
            true -> false
            _ ->
              list =
                Path.reduce(arr, fn(w) ->
                  [:this_goes_nowhere, Path.join(w, ",")]
                end)
          end
        end

        IO.puts "x"
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for |> in :if" do
    """
    defmodule CredoSampleModule do
      def sort_column(col, query) do
        cols = result_columns(query)
        if hd(cols) do
          coercer = fn({name, type}) -> coerce(type, col[Atom.to_string(name)]) end
          cols |> Path.join(coercer)
        else
          [nil]
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for |> in :if when part of a tuple" do
    """
    defmodule CredoSampleModule do
      def sort_column(col, query) do
        cols = result_columns(query)
        if hd(cols) do
          coercer = fn({name, type}) -> coerce(type, col[Atom.to_string(name)]) end
          {cols |> Path.join(coercer), 123}
        else
          [nil]
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for |> in :if when part of a list" do
    """
    defmodule CredoSampleModule do
      def sort_column(col, query) do
        cols = result_columns(query)
        if hd(cols) do
          coercer = fn({name, type}) -> coerce(type, col[Atom.to_string(name)]) end
          [cols |> Path.join(coercer), 123]
        else
          [nil]
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for |> in :if when part of a keyword list" do
    """
    defmodule CredoSampleModule do
      def sort_column(col, query) do
        cols = result_columns(query)
        if hd(cols) do
          coercer = fn({name, type}) -> coerce(type, col[Atom.to_string(name)]) end
          [cols: cols |> Path.join(coercer), number: 123]
        else
          [nil]
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for |> in :if when part of a map" do
    """
    defmodule CredoSampleModule do
      def sort_column(col, query) do
        cols = result_columns(query)
        if hd(cols) do
          coercer = fn({name, type}) -> coerce(type, col[Atom.to_string(name)]) end
          %{cols: cols |> Path.join(coercer), number: 123}
        else
          [nil]
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for ++ in :if" do
    """
    defmodule CredoSampleModule do
      def sort_column(col, query) do
        cols = result_columns(query)
        if hd(cols) do
          coercer = fn({name, type}) -> coerce(type, col[Atom.to_string(name)]) end
          {nil, cols ++ Path.join(cols, coercer)}
        else
          [nil]
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for this" do
    """
    defmodule CredoSampleModule do
      def testcase(configs) do
        if Path.empty?(configs) do
          {:error, "No exec"}
        else
          anything
          {:ok, Path.flat_map(configs, fn x -> x end)}
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        x = parameter1 + parameter2

        Path.join(parameter1, x)

        parameter1
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when end of pipe" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
        |> Path.join(parameter1)

        parameter1
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when buried in :for" do
    """
    defmodule CredoSampleModule do
      defp print_issue(w) do
        for x <- [1, 2, 3] do
          # this goes nowhere!
          Path.join(w, ",")
          x
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when buried in :if" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          [
            :this_goes_nowhere,
            Path.join(w, ",") # THIS is not the last_call!
          ]
          IO.puts "."
        else
          IO.puts "x"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when buried in :else" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          IO.puts "."
        else
          Path.count(filename)
          IO.puts "x"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when buried in :if, :when and :fn 2" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          IO.puts "."
        else
          case check do
            true -> false
            _ ->
              # this goes nowhere!
              Path.reduce(arr, fn(w) ->
                [w, x]
              end)
          end
        end

        IO.puts "x"
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when call is buried in else block but is the last call" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          IO.puts "."
        else
          [:this_goes_nowhere, Path.join(w, ",")] # THIS is not the last_call!
        end

        IO.puts
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when call is buried in else block but is the last call 2" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          IO.puts "."
        else
          [:this_goes_nowhere, Path.join(w, ",")] # THIS is not the last_call!
          IO.puts " "
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "Path.join" == issue.trigger
    end)
  end

  test "it should report several violations" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Path.reject(parameter1, &is_nil/1)
        parameter1
      end
      def some_function2(parameter1, parameter2) do
       Path.reduce(parameter1, parameter2)
       parameter1
       end
       def some_function3(parameter1, parameter2) do
         Path.reduce(parameter1, parameter2)
         parameter1
       end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert 3 == Enum.count(issues)
    end)
  end

  test "it should report a violation when used incorrectly, even inside a :for" do
    """
    defmodule CredoSampleModule do
      defp something(bin) do
        for segment <- Path.flat_map(segment, &(&1.blob)), segment != "" do
          Path.join(segment)
          segment
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "Path.join" == issue.trigger
    end)
  end
end
