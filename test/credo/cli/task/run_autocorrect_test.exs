defmodule Credo.CLI.Task.RunAutocorrectTest do
  use ExUnit.Case, async: true

  alias Credo.CLI.Task.RunAutocorrect

  defmodule CheckOne do
    def autocorrect(file) do
      send(self(), {:check_one, file})
      "check_one"
    end
  end

  defmodule CheckTwo do
    def autocorrect(file) do
      send(self(), {:check_two, file})
      "check_two"
    end
  end

  defmodule CheckThree do
    def autocorrect(file) do
      send(self(), {:check_three, file})
      "check_three"
    end
  end

  describe "run/2" do
    test "calls `autocorrect/1` for each issue with the correct arguments if autocorrect is true" do
      issues = [
        %Credo.Issue{filename: "a", check: CheckTwo},
        %Credo.Issue{filename: "a", check: CheckOne},
        %Credo.Issue{filename: "b", check: CheckThree}
      ]

      exec = %Credo.Execution{autocorrect: true}
      read_fun = fn _ -> "start" end
      write_fun = fn file_path, contents -> send(self(), {:write, file_path, contents}) end
      RunAutocorrect.call(exec, [issues: issues], read_fun, write_fun)
      assert_receive({:check_one, "start"})
      assert_receive({:check_two, "check_one"})
      assert_receive({:check_three, "start"})
      assert_receive({:write, "a", "check_two"})
      assert_receive({:write, "b", "check_three"})
    end

    test "does nothing if autocorrect is false" do
      issues = [
        %Credo.Issue{filename: "a", check: CheckTwo},
        %Credo.Issue{filename: "a", check: CheckOne},
        %Credo.Issue{filename: "b", check: CheckThree}
      ]

      exec = %Credo.Execution{autocorrect: false}
      read_fun = fn _ -> "start" end
      write_fun = fn file_path, contents -> send(self(), {:write, file_path, contents}) end
      RunAutocorrect.call(exec, [issues: issues], read_fun, write_fun)
      refute_receive({:check_one, "start"})
      refute_receive({:check_two, "check_one"})
      refute_receive({:check_three, "start"})
      refute_receive({:write, "a", "check_two"})
      refute_receive({:write, "b", "check_three"})
    end
  end
end
