defmodule Credo.Check.Consistency.FilenamesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.Filenames

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation for nested module" do
    """
    defmodule IEx.Bar do
    end
    """
    |> to_source_file("lib/iex/bar.ex")
    |> refute_issues(@described_check, acronyms: ["IEx"])
  end

  test "it should NOT report violation for nested module and duplicated name" do
    """
    defmodule Foo.Bar do
    end
    """
    |> to_source_file("lib/foo/bar/bar.ex")
    |> refute_issues(@described_check)
  end

  test "it should NOT report violation for root module" do
    """
    defmodule BarTest do
    end
    """
    |> to_source_file("test/bar_test.exs")
    |> refute_issues(@described_check)
  end

  test "it should NOT report violation for PascalCase nested module" do
    """
    defmodule FooWeb.BarWeb do
    end
    """
    |> to_source_file("lib/foo_web/bar_web.ex")
    |> refute_issues(@described_check)
  end

  test "it should NOT report violation for PascalCase nested module with dot" do
    """
    defmodule FooWeb.Bar.Create do
    end
    """
    |> to_source_file("lib/foo_web/bar.create.ex")
    |> refute_issues(@described_check)
  end

  test "it should NOT report violation for file with multiple modules" do
    """
    defmodule Foo.QueryException do
    end

    defmodule Foo.ReportException do
    end
    """
    |> to_source_file("lib/foo/exceptions.ex")
    |> refute_issues(@described_check)
  end

  test "it should NOT report violation for file with single module and implementations for it" do
    """
    defmodule Foo.Bar do
    end

    defimpl Jason.Encoder, for: Foo.Bar do
    end

    defimpl Poison.Encoder, for: Foo.Bar do
    end
    """
    |> to_source_file("lib/foo/bar.ex")
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation for wrong module name" do
    """
    defmodule FooWeb.Baz do
    end
    """
    |> to_source_file("lib/foo_web/bar.ex")
    |> assert_issue(@described_check)
  end

  test "it should report a violation for missing root module" do
    """
    defmodule Bar do
    end
    """
    |> to_source_file("lib/foo/bar.ex")
    |> assert_issue(@described_check)
  end

  test "it should report a violation for extra directory" do
    """
    defmodule Foo.Bar do
    end
    """
    |> to_source_file("lib/foo/schemas/bar.ex")
    |> assert_issue(@described_check)
  end

  test "it should report a violation for missing PascalCase root module" do
    """
    defmodule Foo.Web.Bar do
    end
    """
    |> to_source_file("lib/foo_web/bar.ex")
    |> assert_issue(@described_check)
  end
end
