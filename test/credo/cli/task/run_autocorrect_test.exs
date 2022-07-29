defmodule Credo.CLI.Task.RunAutofixTest do
  use Credo.Test.Case

  alias Credo.CLI.Task.RunAutofix

  defmodule CheckOne do
    def autofix(file, issue) do
      send(self(), {:check_one, file, issue})
      "check_one"
    end
  end

  defmodule CheckTwo do
    def autofix(file, issue) do
      send(self(), {:check_two, file, issue})
      "check_two"
    end
  end

  defmodule CheckThree do
    def autofix(file, issue) do
      send(self(), {:check_three, file, issue})
      "check_three"
    end
  end

  describe "run/2" do
    test "calls `autofix/1` for each issue with the correct arguments if autofix is true" do
      issue1 = %Credo.Issue{filename: "a", check: CheckOne}
      issue2 = %Credo.Issue{filename: "a", check: CheckTwo}
      issue3 = %Credo.Issue{filename: "b", check: CheckThree}

      issues = [issue2, issue1, issue3]

      exec = %Credo.Execution{autofix: true} |> Credo.Execution.ExecutionIssues.start_server()
      read_fun = fn _ -> "start" end
      write_fun = fn file_path, contents -> send(self(), {:write, file_path, contents}) end
      RunAutofix.call(exec, [issues: issues], read_fun, write_fun)
      assert_receive({:check_one, "start", ^issue1})
      assert_receive({:check_two, "check_one", ^issue2})
      assert_receive({:check_three, "start", ^issue3})
      assert_receive({:write, "a", "check_two"})
      assert_receive({:write, "b", "check_three"})
    end

    test "does nothing if autofix is false" do
      issues = [
        %Credo.Issue{filename: "a", check: CheckTwo},
        %Credo.Issue{filename: "a", check: CheckOne},
        %Credo.Issue{filename: "b", check: CheckThree}
      ]

      exec = %Credo.Execution{autofix: false}
      read_fun = fn _ -> "start" end
      write_fun = fn file_path, contents -> send(self(), {:write, file_path, contents}) end
      RunAutofix.call(exec, [issues: issues], read_fun, write_fun)
      refute_receive(_)
    end
  end
end
