defmodule Credo.ExecutionTest do
  use ExUnit.Case

  alias Credo.Execution

  test "it should work" do
    exec = %Execution{
      process: [
        parse_cli_options: [
          {Credo.Execution.Task.ParseOptions, []}
        ],
        validate_cli_options: [
          {Credo.Execution.Task.ValidateOptions, []}
        ]
      ]
    }

    expected_process = [
      parse_cli_options: [
        {Credo.Execution.Task.ParseOptions, []}
      ],
      validate_cli_options: [
        {Credo.ExecutionTest, []},
        {Credo.Execution.Task.ValidateOptions, []}
      ]
    ]

    result = Execution.prepend_task(exec, :validate_cli_options, Credo.ExecutionTest)

    assert expected_process == result.process
  end

  test "it should work for append" do
    exec = %Execution{
      process: [
        parse_cli_options: [
          {Credo.Execution.Task.ParseOptions, []}
        ],
        validate_cli_options: [
          {Credo.Execution.Task.ValidateOptions, []}
        ]
      ]
    }

    expected_process = [
      parse_cli_options: [
        {Credo.Execution.Task.ParseOptions, []}
      ],
      validate_cli_options: [
        {Credo.Execution.Task.ValidateOptions, []},
        {Credo.ExecutionTest, []}
      ]
    ]

    result = Execution.append_task(exec, :validate_cli_options, Credo.ExecutionTest)

    assert expected_process == result.process
  end
end
