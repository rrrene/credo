defmodule Credo.Check.Readability.FunctionNamesTest do
  use Credo.TestHelper

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
    |> refute_issues(@described_check)
  end

  test "it should NOT report expected code 2" do
    """
    defmodule CredoSample do
      defmacro unquote(:{})(args)
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
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
    |> assert_issue(@described_check)
  end

  test "it should report a violation /2" do
    """
    def assertAuthorizedData do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /3" do
    """
    defp credo_SampleFunction do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /4" do
    """
    defmacro credo_Sample_Macro do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /5" do
    """
    defmacrop credo_Sample_Macro_p do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /6" do
    """
    def credoSampleFunction() do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /7" do
    """
    def credoSampleFunction(x, y) do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /8" do
    """
    defmacro credoSampleMacro() do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /9" do
    """
    defmacro credoSampleMacro(x, y) do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /10" do
    """
    def credo_SampleFunction when 1 == 1 do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /11" do
    """
    def credo_SampleFunction(x, y) when x == y do
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /12" do
    """
    defguard credo_SampleGuard(x) when is_integer(x)
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation /13" do
    """
    defguardp credo_SampleGuard(x) when is_integer(x)
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end
end
