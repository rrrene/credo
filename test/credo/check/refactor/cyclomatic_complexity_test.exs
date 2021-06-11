defmodule Credo.Check.Refactor.CyclomaticComplexityTest do
  use Credo.Test.Case

  @described_check Credo.Check.Refactor.CyclomaticComplexity

  def complexity(source) do
    {:ok, ast} = Credo.Code.ast(source)
    @described_check.complexity_for(ast)
  end

  def rounded_complexity(source) do
    source
    |> complexity
  end

  test "it should return the complexity for a function without branches" do
    source = """
    def first_fun do
      x = 1
    end
    """

    # 1 for fun def
    assert 1 == rounded_complexity(source)
  end

  test "it should return the complexity for a function with a single branch" do
    source = """
    def first_fun do
      if some_other_fun, do: call_third_fun
    end
    """

    # 1 for fun def, 1 for :if
    assert 2 == rounded_complexity(source)
  end

  test "it should return the complexity for a function with a single branch /2" do
    source = """
    def first_fun do
      if 1 == 1 or 2 == 2 do
        my_options = %{}
      end
    end
    """

    # 1 for fun def, 1 for :if, 1 for :or
    assert 3 == rounded_complexity(source)
  end

  test "it should return the complexity for a function with multiple branches" do
    source = """
    def first_fun(param) do
      case param do
        1 -> do_something
        2 -> do_something_else
        _ -> do_something_even_more_else
      end
    end
    """

    # 1 for fun def, *0* for :case, 1 for each ->
    assert 4 == rounded_complexity(source)
  end

  test "it should return the complexity for a function with multiple branches containing other branches" do
    source = """
    def first_fun(param) do
      case param do
        1 ->
          if 1 == 1 or 2 == 2 do
            my_options = %{}
          end
        2 -> do_something_else
        _ -> do_something_even_more_else
      end
    end
    """

    # 1 for fun def, *0* for :case, 1 for each ->, 2 for the :if inside the first ->
    assert 6 == rounded_complexity(source)
  end

  test "it should return the complexity for a function with multiple branches containing other branches /2" do
    source = """
    def first_fun do
      if first_condition do
        if second_condition && third_condition, do: call_something
        if fourth_condition || fifth_condition, do: call_something_else
      end
    end
    """

    assert 6 == rounded_complexity(source)
  end

  test "it should return the complexity for a function with multiple branches containing other branches /3" do
    source = """
    def first_fun do
      if first_condition do
        call_something
      else
        if second_condition do
          call_something
        else
          if third_condition, do: call_something
        end
        if fourth_condition, do: call_something_else
      end
    end
    """

    assert 5 == rounded_complexity(source)
  end

  test "it should NOT report expected code" do
    """
    def some_function do
      x = 1
    end
    """
    |> to_source_file
    |> run_check(@described_check, max_complexity: 1)
    |> refute_issues()
  end

  test "it should NOT report expected code /2" do
    """
    def some_function do
      if x == 0, do: x = 1
    end
    """
    |> to_source_file
    |> run_check(@described_check, max_complexity: 1)
    |> assert_issue()
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
    |> run_check(@described_check, max_complexity: 3)
    |> refute_issues()
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
              if params[:foo] do
                params[:foo] |> Check.some_fun
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
              {_def, scope} = Credo.Code.scope_for(source_file.ast, line: line_no)
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
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report a violation" do
    """
    def first_fun do
      if first_condition do
        call_something
      else
        if second_condition do
          call_something
        else
          if third_condition, do: call_something
        end
        if fourth_condition, do: call_something_else
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check, max_complexity: 4)
    |> assert_issue()
  end

  test "it should report a violation on def rather than when" do
    """
    defmodule CredoTest do
    defp foobar(v) when is_atom(v) do
      if first_condition do
        if second_condition && third_condition, do: call_something
        if fourth_condition || fifth_condition, do: call_something_else
      end
    end
    end
    """
    |> to_source_file
    |> run_check(@described_check, max_complexity: 4)
    |> assert_issue()
    |> assert_trigger(:foobar)
  end
end
