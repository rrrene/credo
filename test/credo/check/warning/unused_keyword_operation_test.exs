defmodule Credo.Check.Warning.UnusedKeywordOperationTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.UnusedKeywordOperation

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Keyword.values(parameter1) + parameter2
      end

      def invoke(task) when is_atom(task) do
        Enum.each(Keyword.get(MyAgent.get(:before_hooks), task, []),
          fn([module, fnref]) -> apply(module, fnref, []) end)
        Enum.each(Keyword.get(MyAgent.get(:after_hooks), task, []),
          fn([module, fnref]) -> apply(module, fnref, []) end)
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
        Keyword.values(parameter1)
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
      |> Keyword.values(parameter1)
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
      |> Keyword.values(parameter1)
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
      offset = Keyword.new(line)

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
      if Keyword.new(x1) > Keyword.new(x2) do
        cond do
          Keyword.new(x3) == "" -> IO.puts("1")
          Keyword.new(x) == 15 -> IO.puts("2")
          Keyword.take(x3, 1) == "b" -> IO.puts("2")
        end
      else
        case Keyword.new(x3) do
          0 -> true
          1 -> false
          _ -> something
        end
      end
      unless Keyword.new(x4) == "" do
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
        |> Keyword.take(2)
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
        offset = Keyword.new(line)
        [
            Keyword.values(x, " "), :faint, Keyword.values(w, ","),
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
          [:this_actually_might_return, Keyword.values(w, ","), :ok] # THIS is not the last_call!
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
            [:this_goes_nowhere, Keyword.values(w, ",")]
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
              Keyword.update(arr, [], fn(w) ->
                [:this_might_return, Keyword.values(w, ",")]
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
            reference      -> Keyword.take(reference)
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
            reference      -> Module.concat(Plug.Parsers, Keyword.take(reference))
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
        for segment <- Keyword.has_key?(bin, 1), segment != "", do: segment
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
            Keyword.new(analysis_output)
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
          destructure [username, password], Keyword.values(info.userinfo, ":")
        end

        Keyword.update(opts, [], fn {_k, v} -> is_nil(v) end)
      end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in function call 2" do
    """
      defp print_process(pid_atom, count, own) do
        IO.puts([?", Keyword.values(own, "-")])
        IO.write format_item(Path.to_tuple(path, item), Keyword.keys(item))
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
      [Keyword.values(with, indentation), str]
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
                Keyword.update(arr, [], fn(w) ->
                  [:this_goes_nowhere, Keyword.values(w, ",")]
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

  ##############################################################################
  ##############################################################################

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        x = parameter1 + parameter2

        Keyword.take(parameter1, x)

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
        |> Keyword.take(parameter1)

        parameter1
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
            Keyword.values(w, ",") # THIS is not the last_call!
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
          Keyword.new(filename)
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
              # this goes nowhere
              Keyword.update(arr, [], fn(w) ->
                [:asdf, something]
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
          [:this_goes_nowhere, Keyword.values(w)] # THIS is not the last_call!
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
          [:this_goes_nowhere, Keyword.values(w)] # THIS is not the last_call!
          IO.puts " "
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "Keyword.values" == issue.trigger
    end)
  end

  test "it should report several violations" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Keyword.update(parameter1, [], &is_nil/1)
        parameter1
      end
      def some_function2(parameter1, parameter2) do
       Keyword.update(parameter1, [], parameter2)
       parameter1
       end
       def some_function3(parameter1, parameter2) do
         Keyword.update(parameter1, [], parameter2)
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
        for segment <- Keyword.has_key?(segment1, 1), segment != "" do
          Keyword.split(segment, [:split_me])
          segment
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "Keyword.split" == issue.trigger
    end)
  end
end
