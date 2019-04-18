defmodule Credo.Check.Readability.StringSigilsTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.StringSigils

  def create_snippet(string_literal) do
    """
    defmodule CredoTest do
      @module_var "#{string_literal}"
    end
    """
  end

  def create_sigil_snippet(string_literal, sigil \\ "s") do
    """
    defmodule CredoTest do
      @module_var ~#{sigil}(#{string_literal})
    end
    """
  end

  def create_heredoc_snippet_w_double_quotes(string_literal) do
    """
    defmodule CredoTest do
      @module_var \"\"\"
      #{string_literal}
      \"\"\"
    end
    """
  end

  def create_heredoc_snippet_w_single_quotes(string_literal) do
    """
    defmodule CredoTest do
      @module_var \'\'\'
      #{string_literal}
      \'\'\'
    end
    """
  end

  #
  # cases NOT raising issues
  #

  test "does NOT report for empty string" do
    create_snippet("")
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "does NOT report when exactly 3 quotes are found" do
    ~s(f\\"b\\"\\")
    |> create_snippet()
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "does NOT report when less than :maximum_allowed_quotes quotes are found" do
    ~s(f\\"\\"\\"\\")
    |> create_snippet()
    |> to_source_file
    |> refute_issues(@described_check, maximum_allowed_quotes: 5)
  end

  test "does NOT report when exactly :maximum_allowed_quotes quotes are found" do
    ~s(f\\"\\"\\"\\")
    |> create_snippet()
    |> to_source_file
    |> refute_issues(@described_check, maximum_allowed_quotes: 4)
  end

  test "does NOT report for quotes in sigil_s" do
    ~s(f\\"\\"b\\"\\")
    |> create_sigil_snippet()
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "does NOT report for quotes in sigil_r" do
    ~s(f\\"\\"b\\"\\")
    |> create_sigil_snippet("r")
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "does NOT report for double quotes in heredoc" do
    ~s(f\\"\\"b\\"\\")
    |> create_heredoc_snippet_w_double_quotes()
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "does NOT report for double quotes in heredoc /2" do
    """
    \"\"\"
    {
    "hello": "world",
    "foo": "bar"
    }
    \"\"\"
    |> Jason.decode!
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "does NOT report for single quotes in heredoc" do
    ~s(f\\"\\"b\\"\\")
    |> create_heredoc_snippet_w_single_quotes()
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "does NOT crash if string contains non utf8 characters" do
    snippet = ~S(defmodule CredoTest do
      @module_var "\xFF"
    end)

    snippet
    |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "reports for more than 3 quotes" do
    ~s(f\\"\\"b\\"\\")
    |> create_snippet()
    |> to_source_file
    |> assert_issue(@described_check)
  end

  test "reports for more than :maximum_allowed_quotes quotes" do
    ~s(f\\"\\"b\\"\\\"\\"\\")
    |> create_snippet()
    |> to_source_file
    |> assert_issue(@described_check, maximum_allowed_quotes: 5)
  end
end
