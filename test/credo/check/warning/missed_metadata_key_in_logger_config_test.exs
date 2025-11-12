defmodule Credo.Check.Warning.MissedMetadataKeyInLoggerConfigTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.MissedMetadataKeyInLoggerConfig
  @logger_functions ~w(alert critical debug emergency error info notice warn warning)a

  #
  # cases NOT raising issues
  #

  for fun <- @logger_functions do
    test "it should NOT report when Logger.#{fun}/2 is used with allowed metadata" do
      ~s'''
      defmodule CredoSampleModule do
        def some_function(parameter1, parameter2) do
          Logger.#{unquote(fun)}(fn ->
            "A warning message: #{inspect(1)}"
          end, account_id: 1)
        end
      end
      '''
      |> to_source_file
      |> run_check(@described_check, metadata_keys: [:account_id])
      |> refute_issues()
    end
  end

  for fun <- @logger_functions do
    test "it should NOT report when Logger.#{fun}/1 is used" do
      ~s'''
      defmodule CredoSampleModule do

        def message do
          "Imma message"
        end

        def some_function do
          Logger.#{unquote(fun)} message
        end
      end
      '''
      |> to_source_file
      |> run_check(@described_check)
      |> refute_issues()
    end
  end

  test "it should NOT report when Logger.metadata/1 is used with allowed metadata" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Logger.metadata(account_id: 1)
        Logger.info fn ->
          "A warning message: #{inspect(1)}"
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, metadata_keys: [:account_id])
    |> refute_issues()
  end

  test "it should NOT report when Logger.log/3 is used with allowed metadata" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Logger.log(:info, fn ->
          "A warning message: #{inspect(1)}"
        end, account_id: 1)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, metadata_keys: [:account_id])
    |> refute_issues()
  end

  test "it should NOT report when Logger.log/3 is used with metadata set to :all" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Logger.log(:info, fn ->
          "A warning message: #{inspect(1)}"
        end, account_id: 1)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, metadata_keys: :all)
    |> refute_issues()
  end

  test "it should NOT report when Logger.log/2 is used" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Logger.log(:info, fn ->
          "A warning message: #{inspect(1)}"
        end)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when Logger.log/2 is used with natively supported metadata" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        Logger.debug("test", ansi_color: :yellow)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  for fun <- @logger_functions do
    test "it should report a violation when Logger.#{fun}/2 is used with disallowed metadata" do
      ~s'''
      defmodule CredoSampleModule do

        def some_function(parameter1, parameter2) do
          var_1 = "Hello world"
          Logger.#{unquote(fun)}("The module: #\{var1\}", key: "value")
        end
      end
      '''
      |> to_source_file
      |> run_check(@described_check)
      |> assert_issue(fn issue ->
        assert issue.line_no == 5
      end)
    end
  end

  test "it should report a violation when Logger.metadata/1 is used with disallowed metadata" do
    ~S'''
    defmodule CredoSampleModule do

      def some_function(parameter1, parameter2) do
        Logger.metadata(user_id: 1)
        var_1 = "Hello world"
        Logger.info("The module: #\{var1\}", key: "value")
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn [two, one] ->
      assert one.trigger == "user_id"
      assert one.line_no == 4

      assert two.trigger == "key"
      assert two.line_no == 6
    end)
  end

  test "it should report a violation when Logger.log/3 is used with disallowed metadata" do
    ~S'''
    defmodule CredoSampleModule do

      def some_function(parameter1, parameter2) do
        var_1 = "Hello world"
        Logger.log(:info, "The module: #\{var1\}", key: "value")
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "key"
    end)
  end
end
