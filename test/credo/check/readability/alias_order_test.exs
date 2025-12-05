defmodule Credo.Check.Readability.AliasOrderTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.AliasOrder

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation" do
    ~S'''
    defmodule Test do
      alias App.Module1
      alias App.Module2
      alias Credo.CLI.Command
      alias Credo.CLI.Filename
      alias Credo.CLI.Sorter

      alias Credo.Check
      alias Credo.Check.Params
      alias Credo.CLI.ExitStatus
      alias Credo.Issue
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for independent blocks of alpha-ordered aliases" do
    ~S'''
    defmodule Test do
      alias Credo.CLI.Command
      alias Credo.CLI.Filename
      alias Credo.CLI.Sorter

      alias App.Module1
      alias App.Module2
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation for multi-aliases when they are alpha-ordered" do
    ~S'''
    defmodule Test do
      alias App.CLI.{Filename,Sorter}
      alias App.Foo.{Bar,Baz}

      alias Credo.CLI.Command
      alias Credo.CLI.Filename
      alias Credo.CLI.Sorter

      alias App.Module1
      alias App.Module2
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report with __MODULE__" do
    ~S'''
    defmodule Test do
      alias __MODULE__.SubModule

      alias Credo.CLI.Command
      alias Credo.CLI.Filename
      alias Credo.CLI.Sorter
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report with multi-alias" do
    ~S'''
    defmodule Test do
      alias Detroit.Learnables.Learnable
      alias DetroitWeb.{ContainerCell, WizardNavigationCell, Zzzzz}
      alias DetroitWeb.Course.Subject.{CompletionCell, HeaderCell, TableCell}

      alias Detroit.Abc
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report with an intersecting `require`" do
    ~S'''
    defmodule Test do
      alias OMG.API.State.{Transaction, Transaction.Recovered, Transaction.Signed}
      alias OMG.API.Utxo
      require Utxo
      alias OMG.Watcher.Repo
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report with multi alias syntax" do
    ~S'''
    defmodule Test do
      alias MyApp.Accounts.{Organization, User, UserOrganization}
      alias MyApp.Repo
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report with case-sensitive sorting" do
    ~S'''
    defmodule Test do
      alias MyApp.AlphaBravoCharlie
      alias MyApp.AlphaBravoalpha
    end
    '''
    |> to_source_file
    |> run_check(@described_check, sort_method: :ascii)
    |> refute_issues()
  end

  test "it should NOT report with case-sensitive alias grouping" do
    ~S'''
    defmodule Test do
      alias MyApp.{AlphaBravoCharlie, AlphaBravoalpha}
    end
    '''
    |> to_source_file
    |> run_check(@described_check, sort_method: :ascii)
    |> refute_issues()
  end

  test "it should NOT report for unsorted alias before multi-alias" do
    """
    defmodule MyApp.MyModule do
      alias MyApp.Core.{Account, User}
      alias Phoenix.Controller
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report for unsorted alias before multi-alias /2" do
    """
    defmodule MyApp.MyModule do
      alias Code.Fragment
      alias MyApp.Core.{Account, User}
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    ~S'''
    defmodule CredoSampleModule do
      alias Credo.CLI.Sorter
      alias Credo.CLI.Command
      alias Credo.CLI.Filename
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "Credo.CLI.Sorter"
    end)
  end

  test "it should report a violation with as option" do
    ~S'''
    defmodule CredoSampleModule do
      alias App.Module2
      alias App.Module1, as: Module3
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "App.Module2"
    end)
  end

  test "it should report a violation with alias groups" do
    ~S'''
    defmodule CredoSampleModule do
      alias Credo.CLI.Command
      alias Credo.CLI.Filename
      alias Credo.CLI.Sorter

      alias App.Module2
      alias App.Module1
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "App.Module2"
    end)
  end

  test "it should report a violation for unsorted alias before multi-alias" do
    """
    defmodule MyApp.MyModule do
      alias Phoenix.Controller
      alias MyApp.Core.{Account, User}
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation with multi-alias" do
    ~S'''
    defmodule CredoSampleModule do
      alias App.CLI.{Bar,Baz}
      alias App.Foo.{
        AutoSorter,
        Sorter,
        Command,
        Filename
      }
      alias App.Geek

      alias Credo.CLI.Command
      alias Credo.CLI.Filename
      alias Credo.CLI.Sorter

      alias App.Module1
      alias App.Module2
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "Sorter"
      assert issue.line_no == 5
    end)
  end

  test "it should report a violation with multi-alias /2" do
    ~S'''
    defmodule CredoSampleModule do
      alias Surface.Components.Form
      alias Surface.Components.Form.{DateInput, TextInput, TextArea}
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "TextInput"
    end)
  end

  test "it should report a violation with multi-alias /3" do
    ~S'''
    defmodule CredoSampleModule do
      alias App.CLI.{Bar,Baz}
      alias App.Foo.{Sorter,Command,Filename}

      alias Credo.CLI.Command
      alias Credo.CLI.Filename
      alias Credo.CLI.Sorter

      alias App.Module1
      alias App.Module2
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "Sorter"
    end)
  end

  test "it should report a violation with case-sensitive sorting" do
    ~S'''
    defmodule Test do
      alias MyApp.AlphaBravoalpha
      alias MyApp.AlphaBravoCharlie
    end
    '''
    |> to_source_file
    |> run_check(@described_check, sort_method: :ascii)
    |> assert_issue(fn issue ->
      assert issue.trigger == "MyApp.AlphaBravoalpha"
    end)
  end

  test "it should report a violation with case-sensitive sorting in a multi-alias" do
    ~S'''
    defmodule Test do
      alias MyApp.{AlphaBravoalpha, AlphaBravoCharlie}
    end
    '''
    |> to_source_file
    |> run_check(@described_check, sort_method: :ascii)
    |> assert_issue(fn issue ->
      assert issue.trigger == "AlphaBravoalpha"
    end)
  end
end
