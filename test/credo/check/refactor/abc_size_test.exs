defmodule Credo.Check.Refactor.ABCSizeTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.ABCSize

  def abc_size(source) do
    {:ok, ast} = Credo.Code.ast(source)
    @described_check.abc_size_for(ast)
  end

  def rounded_abc_size(source) do
    source
    |> abc_size
    |> Float.round(2)
  end

  test "it should return the correct ABC size for nullary function calls" do
    source = """
    def foo() do
      baz()
    end
    """

    assert rounded_abc_size(source) == 1.0
  end

  test "it should return the correct ABC size for regular function calls" do
    source = """
    def foo() do
      baz 1, 2
    end
    """

    assert rounded_abc_size(source) == 1.0
  end  

  test "it should return the correct ABC size for value assignment" do
    source = """
    def first_fun do
      x = 1
    end
    """

    # sqrt(1*1 + 0 + 0) = 1
    assert rounded_abc_size(source) == 1.0
  end

  test "it should return the correct ABC size for value assignment 2" do
    source = """
    def first_fun(name) do
      x = "__#\{name}__"
    end
    """

    # sqrt(1*1 + 0 + 0) = 1
    assert rounded_abc_size(source) == 1.0
  end

  test "it should return the correct ABC size for assignment to fun call" do
    source = """
    def first_fun do
      x = call_other_fun
    end
    """

    # sqrt(1*1 + 1*1 + 0) = 1.41
    assert rounded_abc_size(source) == 1.41
  end

  test "it should return the correct ABC size for assignment to module fun call" do
    source = """
    def first_fun do
      x = Some.Other.Module.call_other_fun
    end
    """

    # sqrt(1*1 + 1*1 + 0) = 1.41
    assert rounded_abc_size(source) == 1.41
  end

  test "it should return the correct ABC size /3" do
    source = """
    def first_fun do
      if some_other_fun, do: call_third_fun
    end
    """

    # sqrt(0 + 2*2 + 1*1) = 2.236
    assert rounded_abc_size(source) == 2.24
  end

  test "it should return the correct ABC size /4" do
    source = """
    def first_fun do
      if Some.Other.Module.some_other_fun, do: Some.Other.Module.call_third_fun
    end
    """

    # sqrt(0 + 2*2 + 1*1) = 2.236
    assert rounded_abc_size(source) == 2.24
  end

  test "it should return the correct ABC size /5" do
    source = """
    def some_function(foo, bar) do
      if true == true or false == 2 do
        my_options = MyHash.create
      end
      my_options
      |> Enum.each(fn(key, value) ->
        IO.puts key
        IO.puts value
      end)
    end
    """

    # sqrt(1*1 + 5*5 + 2*2) = 5.48
    assert rounded_abc_size(source) == 5.48
  end

  test "it should NOT report expected code" do
    """
    def some_function do
    end
    """
    |> to_source_file
    |> refute_issues(@described_check, max_size: 0)
  end

  test "it should NOT report expected code /2" do
    """
    def some_function do
      x = 1
    end
    """
    |> to_source_file
    |> assert_issue(@described_check, max_size: 0)
  end

  test "it should NOT report expected code /x" do
    """
    def some_function do
      if 1 == 1 or 2 == 2 do
        my_options = %{}
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check, max_size: 3)
  end

  test "it should NOT report a violation for __using__ macro" do
    ~S"""
    defmodule Credo.Check do
      defmacro __using__(opts) do
        quote do
          def format_issue(issue_meta, opts) do
            source_file = IssueMeta.source_file(issue_meta)
            params = IssueMeta.params(issue_meta)
            priority =
              if params[:priority] do
                params[:priority] |> Check.some_fun
              else
                base_priority
              end

            line_no = opts[:line_no]
            trigger = opts[:trigger]
            column = opts[:column]
            severity = opts[:severity] || Severity.default_value
            issue = %Issue{
              priority: priority,
              filename: source_file.filename,
              message: opts[:message],
              trigger: trigger,
              line_no: line_no,
              column: column,
              severity: severity
            }
            if line_no do
              {_def, scope} = CodeHelper.scope_for(source_file.ast, line: line_no)
              issue =
                %Issue{
                  issue |
                  priority: issue.priority + priority_for(source_file, scope),
                  scope: scope
                }
            end
            if trigger && line_no && !column do
              issue =
                %Issue{
                  issue |
                  column: SourceFile.column(source_file, line_no, trigger)
                }
            end
            format_issue(issue)
          end
          def format_issue(issue \\ %Issue{}) do
            %Issue{
              issue |
              check: __MODULE__,
              category: category
            }
          end

          defp priority_for(source_file, scope) do
            scope_prio_map = Priority.scope_priorities(source_file)
            scope_prio_map[scope] || 0
          end
        end
      end
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report a violation" do
    """
    def some_function do
      if true == true or false == 2 do
        my_options = MyHash.create
      end
      my_options
      |> Enum.each(fn(key, value) ->
        IO.puts key
        IO.puts value
      end)
    end
    """
    |> to_source_file
    |> assert_issue(@described_check, max_size: 3)
  end

  test "it should NOT count map/struct field access with dot notation for abc size" do
    source = """
      def test do
        %{
          foo: foo.bar,
          bar: bar.baz,
          baz: bux.bus
        }
      end
    """

    assert rounded_abc_size(source) == 3
  end
end
