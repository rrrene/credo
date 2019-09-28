defmodule Credo.Check.Readability.PublicFunctionDocTest do
  @moduledoc false

  use Credo.TestHelper

  @described_check Credo.Check.Readability.PublicFunctionDoc

  #
  # cases NOT raising issues
  #

  test "it should NOT report a single line string" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      @doc "Useful function description."
      def public_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report a multiline string" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      @doc \"\"\"
      Useful function description.
      \"\"\"
      def public_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report document metadata" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      @doc "Useful function description."
      @doc deprecated: "Use Foo.bar/2 instead"
      @doc since: "1.3.0"
      def public_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report when disabled" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      @doc false
      def public_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report when spec is declared" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      @doc false
      @spec public_function() :: String.t()
      def public_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report .exs scripts" do
    """
    def public_function do
      "foo"
    end
    """
    |> to_source_file("public_function_doc_test_1.exs")
    |> refute_issues(@described_check)
  end

  test "it should NOT report ignored names with a single string" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      def public_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check, ignore_names: "public_function")
  end

  test "it should NOT report ignored names with a single atom" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      def public_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check, ignore_names: :public_function)
  end

  test "it should NOT report ignored names with a regex" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      def public_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check, ignore_names: ~r/public_function/)
  end

  test "it should NOT report ignored names with a list" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      def public_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check, ignore_names: [:public_function])
  end

  test "it should NOT report non public functions" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      @doc "Useful function description."
      def public_function do
        "foo"
      end

      defp private_function do
        "bar"
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report functions starting with an underscore" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      def _prefixed_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report functions with doc metadata and docs disabled" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      @doc false
      @doc since: "1.3.0"
      def prefixed_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report an undocumented function" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      def public_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report empty strings" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      @doc ""
      def public_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report empty multi line strings" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      @doc \"\"\"

      \"\"\"
      def public_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report functions with only metadata docs" do
    """
    defmodule CredoSampleModule do
      @moduledoc false

      @doc since: "1.3.0"
      def prefixed_function do
        "foo"
      end
    end
    """
    |> to_source_file
    |> assert_issue(@described_check)
  end
end
