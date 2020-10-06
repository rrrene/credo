defmodule Credo.Check.Readability.FunctionNamesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.FunctionNames

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    def credo_sample do
    end
    defp sample do
    end
    defmacro credo_sample_macro do
    end
    defmacrop credo_sample_macro_p do
    end
    defguard credo_sample_guard(x) when is_integer(x)
    defguardp credo_sample_guard(x) when is_integer(x)
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /2" do
    ~S"""
    def unquote(property)(user_id) when is_integer(user_id) do
      get_user_property(user_id, unquote(property))
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /3" do
    ~S"""
    def something(user_id) when is_integer(unquote(property)) do
      nil
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /4" do
    """
    defmodule CredoSample do
      defmacro unquote(:{})(args)
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code /5" do
    """
    def sigil_O(input, args) do
      # ...
    end
    defmacro sigil_U({:<<>>, _, [string]}, []) do
      # ...
    end
    defmacro sigil_U({:<<>>, _, [string]}, []) when is_binary(string) do
      # ...
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report expected code (for operators) /6" do
    """
    defmacro @expr2
    defmacro @expr do
      # ...
    end

    def left ++ right do
      # ++ code
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when acronyms are allowed" do
    """
    def clean_HTTP_url(0), do: :ok
    """
    |> to_source_file
    |> run_check(@described_check, allow_acronyms: true)
    |> refute_issues()
  end

  test "it should NOT report a violation when acronyms are allowed /2" do
    """
    def clean_HTTP2_url(0), do: :ok
    """
    |> to_source_file
    |> run_check(@described_check, allow_acronyms: true)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    def credoSampleFunction do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /2" do
    """
    def assertAuthorizedData do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /3" do
    """
    defp credo_SampleFunction do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /4" do
    """
    defmacro credo_Sample_Macro do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /5" do
    """
    defmacrop credo_Sample_Macro_p do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /6" do
    """
    def credoSampleFunction() do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /7" do
    """
    def credoSampleFunction(x, y) do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /8" do
    """
    defmacro credoSampleMacro() do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /9" do
    """
    defmacro credoSampleMacro(x, y) do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /10" do
    """
    def credo_SampleFunction when 1 == 1 do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /11" do
    """
    def credo_SampleFunction(x, y) when x == y do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /12" do
    """
    defguard credo_SampleGuard(x) when is_integer(x)
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /13" do
    """
    defguardp credo_SampleGuard(x) when is_integer(x)
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /14" do
    """
    def credoSampleFunction(0), do: :ok
    def credoSampleFunction(1), do: :ok
    def credoSampleFunction(2), do: :ok
    def credoSampleFunction(_), do: :ok
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /15" do
    """
    def clean_HTTP_url(0), do: :ok
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
