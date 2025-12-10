defmodule Credo.Check.Warning.LeakyEnvironmentTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.LeakyEnvironment

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      def run_with_system_cmd3(executable, arguments) do
        System.cmd(executable, arguments, env: %{"DB_PASSWORD" => nil})
      end

      def run_with_erlang_open_port(executable, arguments) do
        :erlang.open_port({:spawn_executable, executable}, args: arguments, env: [{'DB_PASSWORD', false}])
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
      def run_with_system_cmd2(executable, arguments) do
        System.cmd(executable, arguments)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 3, trigger: "System.cmd"})
  end

  test "it should report a violation /2" do
    ~S'''
    defmodule CredoSampleModule do
      def run_with_system_cmd3(executable, arguments) do
        System.cmd(executable, arguments, cd: "/tmp")
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 3, trigger: "System.cmd"})
  end

  test "it should report a violation /3" do
    ~S'''
    defmodule CredoSampleModule do
      def run_with_erlang_open_port(executable, arguments) do
        :erlang.open_port({:spawn_executable, executable}, args: arguments)
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 3, column: 5, trigger: ":erlang.open_port"})
  end
end
