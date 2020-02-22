defmodule Credo.Check.Warning.UnusedRegexOperationTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.UnusedRegexOperation

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Regex.compile!(parameter1) + parameter2
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
        Regex.compile!(parameter1)
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
      |> Regex.compile!(parameter1)
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
      |> Regex.compile!(parameter1)
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
      offset = Regex.compile!(line)

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
      if Regex.compile!(x1) > Regex.compile!(x2) do
        cond do
          Regex.compile!(x3) == "" -> IO.puts("1")
          Regex.compile!(x) == 15 -> IO.puts("2")
          Regex.delete_at(x3, 1) == "b" -> IO.puts("2")
        end
      else
        case Regex.compile!(x3) do
          0 -> true
          1 -> false
          _ -> something
        end
      end
      unless Regex.compile!(x4) == "" do
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
        |> Regex.delete_at(2)
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
        offset = Regex.compile!(line)
        [
            Regex.compile!(x, " "), :faint, Regex.compile!(w, ","),
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
          [:this_actually_might_return, Regex.compile!(w, ","), :ok] # THIS is not the last_call!
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
            [:this_goes_nowhere, Regex.compile!(w, ",")]
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
              Regex.insert_at(arr, [], fn(w) ->
                [:this_might_return, Regex.compile!(w, ",")]
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
            reference      -> Regex.delete_at(reference)
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
            reference      -> Module.concat(Plug.Parsers, Regex.delete_at(reference))
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
        for segment <- Regex.append(bin, 1), segment != "", do: segment
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
            Regex.compile!(analysis_output)
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
          destructure [username, password], Regex.compile!(info.userinfo, ":")
        end

        Regex.insert_at(opts, [], fn {_k, v} -> is_nil(v) end)
      end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in function call 2" do
    """
      defp print_process(pid_atom, count, own) do
        IO.puts([?", Regex.compile!(own, "-")])
        IO.write format_item(Path.to_Regex(path, item), Regex.compile!(item))
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
      [Regex.compile!(with, indentation), str]
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
                Regex.insert_at(arr, [], fn(w) ->
                  [:this_goes_nowhere, Regex.compile!(w, ",")]
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

        Regex.delete_at(parameter1, x)

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
        |> Regex.delete_at(parameter1)

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
            Regex.compile!(w, ",") # THIS is not the last_call!
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
          Regex.compile!(filename)
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
              Regex.insert_at(arr, [], fn(w) ->
                [:this_goes_nowhere, x]
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
          [:this_goes_nowhere, Regex.compile!(w, ",")] # THIS is not the last_call!
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
          [:this_goes_nowhere, Regex.compile!(w, ",")] # THIS is not the last_call!
          IO.puts " "
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "Regex.compile!" == issue.trigger
    end)
  end

  test "it should report several violations" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Regex.insert_at(parameter1, [], &is_nil/1)
        parameter1
      end
      def some_function2(parameter1, parameter2) do
       Regex.insert_at(parameter1, [], parameter2)
       parameter1
       end
       def some_function3(parameter1, parameter2) do
         Regex.insert_at(parameter1, [], parameter2)
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
        for segment <- Regex.append(segment1, 1), segment != "" do
          Regex.insert_at(segment, 1, [:added_to_the_tail])
          segment
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "Regex.insert_at" == issue.trigger
    end)
  end
end
