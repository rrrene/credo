defmodule Credo.Check.Readability.SeparateAliasImportRequireUseTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.SeparateAliasRequire

  test "it should NOT report violation on consecutive aliases" do
    """
    defmodule Test do
      alias App.Module1
      alias App.Module2
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on consecutive single-line multi-aliases" do
    """
    defmodule Test do
      alias App.{Module1, Module2}
      alias App.Module2
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on consecutive multi-line multi-aliases" do
    """
    defmodule Test do
      alias App

      alias App.{
        Module1,
        Module2
      }

      alias App.Module3
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on consecutive requires" do
    """
    defmodule Test do
      require App.Module1
      require App.Module2
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on functions named require or alias" do
    """
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
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on multiline alias as" do
    """
    defmodule Test do
      alias App.Module1

      alias App.Module2,
        as: Module3

      alias App.Module4
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on macro quotes" do
    """
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
      def run(%SourceFile{} = source_file, params \\\\ []) do
        issue_meta = IssueMeta.for(source_file, params)

        Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on separate requires" do
    """
    defmodule Test do
      require App.Module1

      require App.Module2
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on separate aliases" do
    """
    defmodule Test do
      alias App.Module1

      alias App.Module2
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should report violation on separate multi-line multi-aliases" do
    """
    defmodule Test do
      alias App

      alias App.{
        Module1,
        Module2
      }

      require App.Module5

      alias App.Module3
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should NOT report violation on separate single-line multi-aliases" do
    """
    defmodule Test do
      alias App.{Module1, Module2}

      alias App.Module2
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end
end
