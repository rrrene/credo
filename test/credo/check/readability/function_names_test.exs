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
end
