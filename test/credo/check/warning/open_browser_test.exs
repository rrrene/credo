defmodule Credo.Check.Warning.OpenBrowserTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.OpenBrowser

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(_view) do
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report code that includes open_browser" do
    """
    defmodule CredoSampleModule do
      def some_function(view) do
        open_browser(view)
        # open_browser(view)
      end
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issues()
  end
end
