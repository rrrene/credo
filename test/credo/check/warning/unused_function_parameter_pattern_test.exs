defmodule Credo.Check.Warning.UnusedFunctionParameterPatternTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.UnusedFunctionParameterPattern

  test "it should NOT report used variables in patterns" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(%{id: id} = user) do
        id
      end

      def another_function(user = %{id: id}) do
        id
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report normal ignored variables" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(_parameter1) do
        :ok
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report a violation when pattern matching and ignoring" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(%{} = _ignored) do
        :ok
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{trigger: "="})
  end

  test "it should report a violation when pattern matching and ignoring (flipped)" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(_ignored = %{}) do
        :ok
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{trigger: "="})
  end

  test "it should report a violation in defp" do
    ~S'''
    defmodule CredoSampleModule do
      defp some_function(%{} = _ignored) do
        :ok
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{trigger: "="})
  end

  test "it should report a violation in defmacro" do
    ~S'''
    defmodule CredoSampleModule do
      defmacro some_macro(%{} = _ignored) do
        :ok
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{trigger: "="})
  end

  test "it should report a violation with when clause" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(%{} = _ignored) when is_map(_ignored) do
        :ok
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{trigger: "="})
  end

  test "it should report multiple violations" do
    ~S'''
    defmodule CredoSampleModule do
      def some_function(%{} = _ignored1, [%{}] = _ignored2) do
        :ok
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues(2)
  end

  test "it should report nested violations" do
    ~S'''
    defmodule CredoSampleModule do
      def nested_list([%{} = _ignored]) do
        :ok
      end

      def nested_tuple({%{} = _ignored, _other}) do
        :ok
      end
    end
    '''
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues(2)
  end
end
