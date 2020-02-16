defmodule Credo.Check.Warning.UnusedEnumOperationTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.UnusedEnumOperation

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Enum.join(parameter1) + parameter2
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
        Enum.join(parameter1)
        |> some_where

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
      |> Enum.join(parameter1)
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
      |> Enum.join(parameter1)
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
      offset = Enum.count(line)

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
        if Enum.count(x1) > Enum.count(x2) do
          cond do
            Enum.count(x3) == "" -> IO.puts("1")
            Enum.count(x) == 15 -> IO.puts("2")
            Enum.at(x3, 1) == "b" -> IO.puts("2")
          end
        else
          case Enum.count(x3) do
            0 -> true
            1 -> false
            _ -> something
          end
        end
        unless Enum.count(x4) == "" do
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
          |> Enum.at(2)
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
        offset = Enum.count(line)
        [
            Enum.join(x, " "), :faint, Enum.join(w, ","),
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
          [:this_actually_might_return, Enum.join(w, ","), :ok] # THIS is not the last_call!
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
            [:this_goes_nowhere, Enum.join(w, ",")]
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
              Enum.map(arr, fn(w) ->
                [:this_might_return, Enum.join(w, ",")]
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
            reference      -> Enum.at(reference)
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
            reference      -> Module.concat(Plug.Parsers, Enum.at(reference))
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
        for x <- Enum.flat_map(bin, &(&1.blob)), x != "", do: x
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
        for x <- [1..3, 5..10], sum=Enum.sum(x), do: sum
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
            Enum.count(analysis_output)
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
          destructure [username, password], Enum.join(info.userinfo, ":")
        end

        Enum.reject(opts, fn {_k, v} -> is_nil(v) end)
      end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in function call /2" do
    """
      defp print_process(pid_atom, count, own) do
        IO.puts([?", Enum.join(own, "-")])
        IO.write format_item(Path.join(path, item), Enum.take(item, width))
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
      [Enum.join(with, indentation), str]
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
                Enum.map(arr, fn(w) ->
                  [:this_goes_nowhere, Enum.join(w, ",")]
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
          cols |> Enum.map(coercer)
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
          {cols |> Enum.map(coercer), 123}
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
          [cols |> Enum.map(coercer), 123]
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
          [cols: cols |> Enum.map(coercer), number: 123]
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
          %{cols: cols |> Enum.map(coercer), number: 123}
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
          {nil, cols ++ Enum.map(cols, coercer)}
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
        if Enum.empty?(configs) do
          {:error, "No exec"}
        else
          anything

          {:ok, Enum.flat_map(configs, fn x -> x end)}
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for Enum.map inside Agent.update" do
    """
    defmodule CredoTest do
      def agent_update do
        Agent.start_link(fn -> 0 end, name: __MODULE__)

        Agent.update(__MODULE__, fn _ ->
          Enum.map([1, 2, 3], fn a -> a end)
        end)

        Agent.get(__MODULE__, fn val -> val end)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for last statement before rescue" do
    """
    defmodule CredoSampleModule do
      def testcase(configs) do
        Enum.empty?(configs)
      rescue
        _ ->
          raise "whatever"
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for last statement before rescue /2" do
    """
    defmodule CredoSampleModule do
      def testcase(configs) do
        try do
          Enum.empty?(configs)
        rescue
          _ ->
            raise "whatever"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation for function calls to erlang modules" do
    """
    defmodule CredoSampleModule do
      def testcase(configs) do
        :ets.insert(table, Enum.map([1, 2, 3, 4], fn i -> i + 1 end))

        :ok
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  #
  #

  test "it should report a violation when NOT the last statement in rescue block" do
    """
    defmodule CredoSampleModule do
      def testcase(configs) do
        try do
          configs
        rescue
          _ ->
            Enum.empty?(configs)

            raise "whatever"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for Enum.map inside Agent.update" do
    """
    defmodule CredoTest do
      def agent_update do
        Agent.start_link(fn -> 0 end, name: __MODULE__)

        Agent.update(__MODULE__, fn _ ->
          Enum.map([1, 2, 3], fn a -> a + 5 end)

          something_else
        end)

        Agent.get(__MODULE__, fn val -> val end)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation for Enum.map inside assigned :if" do
    """
    defmodule CredoTest do
      def agent_update do
        Agent.start_link(fn -> 0 end, name: __MODULE__)

        x =
          case x do
            nil ->
              x
            _ ->
              Enum.map([1, 2, 3], fn a -> a + 5 end)

              something_else
          end

        Agent.get(__MODULE__, fn val -> val end)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        x = parameter1 + parameter2

        Enum.at(parameter1, x)

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
        |> Enum.at(parameter1)

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
          Enum.join(w, ",")

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
            Enum.join(w, ",") # THIS is not the last_call!
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
          Enum.count(filename)
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
            true ->
              false
            _ ->
              # this goes nowhere!
              Enum.map(arr, fn(w) ->
                [:this_goes_nowhere, Enum.join(w, ",")] # <-- this one is not counted
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
          [:this_goes_nowhere, Enum.join(w, ",")] # THIS is not the last_call!
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
          [:this_goes_nowhere, Enum.join(w, ",")] # THIS is not the last_call!

          IO.puts " "
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "Enum.join" == issue.trigger
    end)
  end

  test "it should report several violations" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Enum.reject(parameter1, &is_nil/1)
        parameter1
      end
      def some_function2(parameter1, parameter2) do
       Enum.map(parameter1, parameter2)
       parameter1
       end
       def some_function3(parameter1, parameter2) do
         Enum.map(parameter1, parameter2)
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
        for segment <- Enum.flat_map(segment, &(&1.blob)), segment != "" do
          # this goes nowhere!
          Enum.map(segment, &IO.inspect/1)

          segment
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "Enum.map" == issue.trigger
    end)
  end
end
