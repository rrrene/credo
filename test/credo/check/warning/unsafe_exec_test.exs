defmodule Credo.Check.Warning.UnsafeExecTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.UnsafeExec

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      def run_with_system_cmd2(executable, arguments) do
        System.cmd(executable, arguments)
      end

      def run_with_system_cmd3(executable, arguments) do
        System.cmd(executable, arguments, [])
      end

      def run_with_erlang_open_port(executable, arguments) do
        :erlang.open_port({:spawn_executable, executable}, args: arguments)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    ~S'''
    defmodule CredoSampleModule do
      def run_with_os_cmd(command_line) do
        :os.cmd(command_line)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 3, column: 5, trigger: ":os.cmd"})
  end

  test "it should report a violation /2" do
    ~S'''
    defmodule CredoSampleModule do
      def run_with_os_cmd(command_line) do
        :os.cmd(command_line, [])
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 3, column: 5, trigger: ":os.cmd"})
  end

  test "it should report a violation /3" do
    ~S'''
    defmodule CredoSampleModule do
      def run_with_erlang_open_port(command_line) do
        :erlang.open_port({:spawn, command_line}, [])
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 3, column: 5, trigger: ":erlang.open_port"})
  end
end
