defmodule Credo.Check.Warning.ApplicationConfigInModuleAttributeTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.ApplicationConfigInModuleAttribute

  #
  # cases NOT raising issues
  #

  test "it should NOT report an issue if compile_env and compile_env! are used" do
    """
    defmodule CredoSampleModule do
      @config_1 Application.compile_env!(:my_app, :key)
      @config_2 Application.compile_env(:my_app, :key, :default)
      @config_3 Application.compile_env(:my_app, :key)
      @config_4 :some_hard_coded_value

      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      @config_1 Application.fetch_env(:my_app, :key)
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "Application.fetch_env"
    end)
  end

  test "it should report a violation when bad calls are made" do
    issues =
      """
      defmodule CredoSampleModule do
        @config_1 Application.fetch_env(:my_app, :key)
        @config_2 :valid
        @config_3 Application.fetch_env!(:my_app, :key)
        @config_4 "Another value"
        @config_5 Application.get_all_env(:my_app)
        @config_6 999_999_999
        @config_7 Application.get_env(:my_app, :key)
        @config_8 "More padding"
        @config_9 Application.get_env(:my_app, :key, :some_default)

        def some_function(parameter1, parameter2) do
          IO.inspect parameter1 + parameter2
        end
      end
      """
      |> to_source_file
      |> run_check(@described_check)

    assert_issues = [
      {
        "Module attribute @config_1 makes use of unsafe Application configuration call Application.fetch_env/2",
        {2, 13},
        "Application.fetch_env"
      },
      {
        "Module attribute @config_3 makes use of unsafe Application configuration call Application.fetch_env!/2",
        {4, 13},
        "Application.fetch_env"
      },
      {
        "Module attribute @config_5 makes use of unsafe Application configuration call Application.get_all_env/1",
        {6, 13},
        "Application.get_all_env"
      },
      {
        "Module attribute @config_7 makes use of unsafe Application configuration call Application.get_env/2",
        {8, 13},
        "Application.get_env"
      },
      {
        "Module attribute @config_9 makes use of unsafe Application configuration call Application.get_env/3",
        {10, 13},
        "Application.get_env"
      }
    ]

    assert length(issues) == 5

    Enum.each(assert_issues, fn {error_message, pos, trigger} ->
      assert error_exists?(issues, error_message, pos, trigger)
    end)
  end

  defp error_exists?(errors, error_message, {line_no, column}, trigger) do
    Enum.any?(errors, fn
      %Credo.Issue{message: ^error_message, line_no: ^line_no, column: ^column, trigger: ^trigger} ->
        true

      _ ->
        false
    end)
  end
end
