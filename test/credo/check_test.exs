defmodule Credo.CheckTest do
  use Credo.Test.Case

  import ExUnit.CaptureIO

  alias Credo.Check

  @generated_lines 1000
  test "it should determine the correct scope for long modules in reasonable time" do
    source_file =
      ~s'''
      # some_file.ex
      defmodule AliasTest do
        def test do
          [
      #{for _ <- 1..@generated_lines, do: "      :a,\n"}
            :a
          ]

          Any.Thing.test()
        end
      end
      '''
      |> to_source_file

    {time_in_microseconds, result} =
      :timer.tc(fn ->
        Check.scope_for(source_file, line: @generated_lines + 9)
      end)

    # Ensures that there are no speed pitfalls like reported here:
    # https://github.com/rrrene/credo/issues/702
    assert time_in_microseconds < 1_000_000
    assert {:def, "AliasTest.test"} == result
  end

  defmodule DocsUriTestCheck do
    use Credo.Check, docs_uri: "https://example.org"

    def run(%SourceFile{} = _source_file, _params \\ []) do
      []
    end
  end

  test "it should use/generate a docs_uri" do
    assert DocsUriTestCheck.docs_uri() == "https://example.org"

    assert Credo.Check.Readability.ModuleDoc.docs_uri() ==
             "https://hexdocs.pm/credo/Credo.Check.Readability.ModuleDoc.html"
  end

  test "it should use/generate an id" do
    assert DocsUriTestCheck.id() == "Credo.CheckTest.DocsUriTestCheck"

    assert Credo.Check.Readability.ModuleDoc.id() == "EX3009"
  end

  defmodule MyCustomCheck1 do
    use Credo.Check, category: :example, base_priority: :high

    def run(%SourceFile{} = source_file, params \\ []) do
      issue_meta = IssueMeta.for(source_file, params)

      [
        format_issue(issue_meta,
          priority: 113,
          trigger: :foobar,
          line_no: 3,
          column: 15,
          exit_status: 23,
          severity: 11,
          category: :custom_category
        )
      ]
    end
  end

  test "it should use format_issue/2" do
    ~S'''
    defmodule AliasTest do
      def test do
        Any.Thing.foobar()
      end
    end
    '''
    |> to_source_file
    |> run_check(MyCustomCheck1)
    |> assert_issue(%{
      priority: 113,
      trigger: "foobar",
      line_no: 3,
      column: 15,
      exit_status: 23,
      severity: 11,
      category: :custom_category
    })
  end

  defmodule IssueInvalidMessageTestCheck do
    use Credo.Check

    @message <<70, 111, 117, 110, 100, 32, 109, 105, 115, 115, 112, 101, 108, 108, 101, 100, 32,
               119, 111, 114, 100, 32, 96, 103, 97, 114, 114, 121, 226, 96, 46>>

    def run(%SourceFile{} = source_file, params \\ []) do
      IssueMeta.for(source_file, params) |> format_issue(message: @message) |> List.wrap()
    end
  end

  test "it should handle an invalid message" do
    stderr_output =
      capture_io(:stderr, fn ->
        "# we do not need code, as the check is creating an issue in any case"
        |> to_source_file
        |> run_check(IssueInvalidMessageTestCheck)
      end)

    assert stderr_output != ""
    assert stderr_output =~ "containing invalid bytes"
  end

  test "it should recognize defined checks" do
    assert Check.defined?(Credo.Check.Refactor.Nesting)
  end

  test "it should not recognize defined modules as checks" do
    refute Check.defined?(Credo.Check.Refactor.EnumHelpers)
  end

  defmodule ModuleAttributeTestCheck do
    @check_explanation "This is stored in a module attribute"
    @param_explanation "Parameter from module attribute"

    use Credo.Check,
      category: :warning,
      explanations: [
        check: @check_explanation,
        params: [some_param: @param_explanation, other_param: "<#{@param_explanation}>"]
      ],
      param_defaults: [some_param: 42]

    def run(%SourceFile{} = _source_file, _params \\ []) do
      []
    end
  end

  test "it should allow module attributes in use Credo.Check options" do
    explanations = ModuleAttributeTestCheck.explanations()
    assert explanations[:check] == "This is stored in a module attribute"
    assert explanations[:params][:some_param] == "Parameter from module attribute"
    assert explanations[:params][:other_param] == "<Parameter from module attribute>"
  end
end
