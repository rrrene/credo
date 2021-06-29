defmodule Credo.ExecutionTest do
  use ExUnit.Case

  alias Credo.Execution

  test "it should work for append_task/4" do
    exec = %Execution{
      pipeline_map: %{
        Execution => [
          parse_cli_options: [
            {Credo.Execution.Task.ParseOptions, []}
          ],
          validate_cli_options: [
            {Credo.Execution.Task.ValidateOptions, []}
          ]
        ]
      }
    }

    expected_pipeline_map = %{
      Execution => [
        parse_cli_options: [
          {Credo.Execution.Task.ParseOptions, []}
        ],
        validate_cli_options: [
          {Credo.Execution.Task.ValidateOptions, []},
          {Credo.ExecutionTest, []}
        ]
      ]
    }

    result = Execution.append_task(exec, Credo, nil, :validate_cli_options, Credo.ExecutionTest)

    assert expected_pipeline_map == result.pipeline_map
  end

  test "it should work for prepend_task/4" do
    exec = %Execution{
      pipeline_map: %{
        Execution => [
          parse_cli_options: [
            {Credo.Execution.Task.ParseOptions, []}
          ],
          validate_cli_options: [
            {Credo.Execution.Task.ValidateOptions, []}
          ]
        ]
      }
    }

    expected_pipeline_map = %{
      Execution => [
        parse_cli_options: [
          {Credo.Execution.Task.ParseOptions, []}
        ],
        validate_cli_options: [
          {Credo.ExecutionTest, []},
          {Credo.Execution.Task.ValidateOptions, []}
        ]
      ]
    }

    result = Execution.prepend_task(exec, Credo, nil, :validate_cli_options, Credo.ExecutionTest)

    assert expected_pipeline_map == result.pipeline_map
  end

  test "it should work for append_task/5 for Credo.CLI.Command.Suggest.SuggestCommand" do
    pipeline_key = Credo.CLI.Command.Suggest.SuggestCommand

    exec = %Execution{
      pipeline_map: %{
        Credo.CLI.Command.Suggest.SuggestCommand => [
          parse_cli_options: [
            {Credo.Execution.Task.ParseOptions, []}
          ],
          validate_cli_options: [
            {Credo.Execution.Task.ValidateOptions, []}
          ]
        ]
      }
    }

    expected_pipeline_map = %{
      Credo.CLI.Command.Suggest.SuggestCommand => [
        parse_cli_options: [
          {Credo.Execution.Task.ParseOptions, []}
        ],
        validate_cli_options: [
          {Credo.Execution.Task.ValidateOptions, []},
          {Credo.ExecutionTest, []}
        ]
      ]
    }

    result =
      Execution.append_task(exec, Credo, pipeline_key, :validate_cli_options, Credo.ExecutionTest)

    assert expected_pipeline_map == result.pipeline_map
  end

  test "it should work for prepend_task/5 for Credo.CLI.Command.Suggest.SuggestCommand" do
    pipeline_key = Credo.CLI.Command.Suggest.SuggestCommand

    exec = %Execution{
      pipeline_map: %{
        Credo.CLI.Command.Suggest.SuggestCommand => [
          parse_cli_options: [
            {Credo.Execution.Task.ParseOptions, []}
          ],
          validate_cli_options: [
            {Credo.Execution.Task.ValidateOptions, []}
          ]
        ]
      }
    }

    expected_pipeline_map = %{
      Credo.CLI.Command.Suggest.SuggestCommand => [
        parse_cli_options: [
          {Credo.Execution.Task.ParseOptions, []}
        ],
        validate_cli_options: [
          {Credo.ExecutionTest, []},
          {Credo.Execution.Task.ValidateOptions, []}
        ]
      ]
    }

    result =
      Execution.prepend_task(
        exec,
        Credo,
        pipeline_key,
        :validate_cli_options,
        Credo.ExecutionTest
      )

    assert expected_pipeline_map == result.pipeline_map
  end

  test "it should work for append_task/5 for suggest when using old syntax" do
    pipeline_key = Credo.CLI.Command.Suggest.SuggestCommand

    exec = %Execution{
      pipeline_map: %{
        "suggest" => [
          parse_cli_options: [
            {Credo.Execution.Task.ParseOptions, []}
          ],
          validate_cli_options: [
            {Credo.Execution.Task.ValidateOptions, []}
          ]
        ]
      }
    }

    expected_pipeline_map = %{
      "suggest" => [
        parse_cli_options: [
          {Credo.Execution.Task.ParseOptions, []}
        ],
        validate_cli_options: [
          {Credo.Execution.Task.ValidateOptions, []},
          {Credo.ExecutionTest, []}
        ]
      ]
    }

    result =
      Execution.append_task(exec, Credo, pipeline_key, :validate_cli_options, Credo.ExecutionTest)

    assert expected_pipeline_map == result.pipeline_map
  end

  test "it should work for prepend_task/5 for suggest when using old syntax" do
    pipeline_key = Credo.CLI.Command.Suggest.SuggestCommand

    exec = %Execution{
      pipeline_map: %{
        "suggest" => [
          parse_cli_options: [
            {Credo.Execution.Task.ParseOptions, []}
          ],
          validate_cli_options: [
            {Credo.Execution.Task.ValidateOptions, []}
          ]
        ]
      }
    }

    expected_pipeline_map = %{
      "suggest" => [
        parse_cli_options: [
          {Credo.Execution.Task.ParseOptions, []}
        ],
        validate_cli_options: [
          {Credo.ExecutionTest, []},
          {Credo.Execution.Task.ValidateOptions, []}
        ]
      ]
    }

    result =
      Execution.prepend_task(
        exec,
        Credo,
        pipeline_key,
        :validate_cli_options,
        Credo.ExecutionTest
      )

    assert expected_pipeline_map == result.pipeline_map
  end
end
