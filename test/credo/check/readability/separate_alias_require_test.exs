defmodule Credo.Check.Readability.SeparateAliasImportRequireUseTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.SeparateAliasRequire

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation on consecutive aliases" do
    ~S'''
    defmodule Test do
      alias App.Module1
      alias App.Module2
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on consecutive single-line multi-aliases" do
    ~S'''
    defmodule Test do
      alias App.{Module1, Module2}
      alias App.Module2
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on consecutive multi-line multi-aliases" do
    ~S'''
    defmodule Test do
      alias App

      alias App.{
        Module1,
        Module2
      }

      alias App.Module3
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on consecutive requires" do
    ~S'''
    defmodule Test do
      require App.Module1
      require App.Module2
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on functions named require or alias" do
    ~S'''
    defmodule Test do
      alias Foo
      require Foo

      defp require do
        :foo
      end

      defp alias do
        :foo
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on multiline alias as" do
    ~S'''
    defmodule Test do
      alias App.Module1

      alias App.Module2,
        as: Module3

      alias App.Module4
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on macro quotes" do
    ~S'''
    defmodule Test do
      require Foo
      alias App.Module1

      defmacro __using__ do
        quote do
          alias App.Module2
        end
      end

      @doc false
      @impl true
      def run(%SourceFile{} = source_file, params \\ []) do
        issue_meta = IssueMeta.for(source_file, params)

        Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on separate requires" do
    ~S'''
    defmodule Test do
      require App.Module1

      require App.Module2
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on separate aliases" do
    ~S'''
    defmodule Test do
      alias App.Module1

      alias App.Module2
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on separate single-line multi-aliases" do
    ~S'''
    defmodule Test do
      alias App.{Module1, Module2}

      alias App.Module2
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report violation on separate multi-line multi-aliases" do
    ~S'''
    defmodule Test do
      alias App

      alias App.{
        Module1,
        Module2
      }

      require App.Module5

      alias App.Module3
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.line_no == 11
      assert issue.trigger == "alias"
    end)
  end
end
