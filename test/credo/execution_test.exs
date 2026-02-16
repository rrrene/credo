defmodule Credo.ExecutionTest do
  use ExUnit.Case

  alias Credo.Execution

  setup do
    [exec: %Execution{config: %Execution.RuntimeConfig{}, private: %Execution.Private{}}]
  end

  test "it should work for put_assign & get_assign", %{exec: exec} do
    exec = Execution.put_assign(exec, "foo", "bar")

    assert Execution.get_assign(exec, "foo") == "bar"
  end

  test "it should work for put_assign_in /1", %{exec: exec} do
    exec =
      Execution.put_assign(
        exec,
        ["credo.magic_funs", :foo],
        "bar"
      )

    assert Execution.get_assign(exec, "credo.magic_funs") == %{foo: "bar"}

    assert Execution.get_assign(exec, ["credo.magic_funs", :none_existing], :baz) == :baz
  end

  test "it should work for put_assign_in and get_assign /2", %{exec: exec} do
    exec =
      Execution.put_assign(
        exec,
        ["credo.magic_funs", Credo.Check.Readability.ModuleDoc, "foo"],
        "bar"
      )

    assert Execution.get_assign(exec, "credo.magic_funs") ==
             %{Credo.Check.Readability.ModuleDoc => %{"foo" => "bar"}}

    assert Execution.get_assign(exec, [
             "credo.magic_funs",
             Credo.Check.Readability.ModuleDoc,
             "foo"
           ]) == "bar"
  end

  test "it should work for append_task/4", %{exec: exec} do
    exec =
      Execution.put_private(exec, :pipeline_map, %{
        Execution => [
          parse_cli_options: [
            {Credo.Execution.Task.ParseOptions, []}
          ],
          validate_cli_options: [
            {Credo.Execution.Task.ValidateOptions, []}
          ]
        ]
      })

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

    assert expected_pipeline_map == Execution.get_private(result, :pipeline_map)
  end

  test "it should work for prepend_task/4", %{exec: exec} do
    exec =
      Execution.put_private(exec, :pipeline_map, %{
        Execution => [
          parse_cli_options: [
            {Credo.Execution.Task.ParseOptions, []}
          ],
          validate_cli_options: [
            {Credo.Execution.Task.ValidateOptions, []}
          ]
        ]
      })

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

    assert expected_pipeline_map == Execution.get_private(result, :pipeline_map)
  end

  test "it should work for append_task/5 for Credo.CLI.Command.Suggest.SuggestCommand", %{
    exec: exec
  } do
    pipeline_key = Credo.CLI.Command.Suggest.SuggestCommand

    exec =
      Execution.put_private(exec, :pipeline_map, %{
        Credo.CLI.Command.Suggest.SuggestCommand => [
          parse_cli_options: [
            {Credo.Execution.Task.ParseOptions, []}
          ],
          validate_cli_options: [
            {Credo.Execution.Task.ValidateOptions, []}
          ]
        ]
      })

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

    assert expected_pipeline_map == Execution.get_private(result, :pipeline_map)
  end

  test "it should work for prepend_task/5 for Credo.CLI.Command.Suggest.SuggestCommand", %{
    exec: exec
  } do
    pipeline_key = Credo.CLI.Command.Suggest.SuggestCommand

    exec =
      Execution.put_private(exec, :pipeline_map, %{
        Credo.CLI.Command.Suggest.SuggestCommand => [
          parse_cli_options: [
            {Credo.Execution.Task.ParseOptions, []}
          ],
          validate_cli_options: [
            {Credo.Execution.Task.ValidateOptions, []}
          ]
        ]
      })

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

    assert expected_pipeline_map == Execution.get_private(result, :pipeline_map)
  end

  test "it should work for append_task/5 for suggest when using old syntax", %{exec: exec} do
    pipeline_key = Credo.CLI.Command.Suggest.SuggestCommand

    exec =
      Execution.put_private(exec, :pipeline_map, %{
        "suggest" => [
          parse_cli_options: [
            {Credo.Execution.Task.ParseOptions, []}
          ],
          validate_cli_options: [
            {Credo.Execution.Task.ValidateOptions, []}
          ]
        ]
      })

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

    assert expected_pipeline_map == Execution.get_private(result, :pipeline_map)
  end

  test "it should work for prepend_task/5 for suggest when using old syntax", %{exec: exec} do
    pipeline_key = Credo.CLI.Command.Suggest.SuggestCommand

    exec =
      Execution.put_private(exec, :pipeline_map, %{
        "suggest" => [
          parse_cli_options: [
            {Credo.Execution.Task.ParseOptions, []}
          ],
          validate_cli_options: [
            {Credo.Execution.Task.ValidateOptions, []}
          ]
        ]
      })

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

    assert expected_pipeline_map == Execution.get_private(result, :pipeline_map)
  end
end
