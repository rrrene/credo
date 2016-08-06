defmodule Credo.Check.Design.AliasUsageTest do
  use Credo.TestHelper

  @described_check Credo.Check.Design.AliasUsage

  #
  # single alias cases
  #

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  alias ExUnit.Case

  def fun1 do
    Case.something

    {:error, reason} = __MODULE__.Sup.start_link(fn() -> :foo end)

    [:faint, filename]    # should not throw an error since
    |> IO.ANSI.format     # IO.ANSI is part of stdlib
    |> Credo.Foo.Code.run # Code is part of the stdlib, aliasing it would
                          # override that `Code`, which you probably don't want
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report violation in `@spec`s" do
"""
defmodule Sample do
  alias Sample.Foo

  @spec foo(Sample.Foo.t) :: false
  def foo(%Foo{} = _), do: false
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report violation on impossible additional alias" do
"""
defmodule Test do
  alias Exzmq.Socket
  alias Exzmq.Tcp

  def just_an_example do
    Socket.test1  # Exzmq.Socket.test
    Tcp.Socket.test2 # Exzmq.Tcp.Socket.test – how can this be further aliased?
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report violation in case of ambiguous module deps" do
"""
defmodule Test do
  def just_an_example do
    Switch.Uri.parse Sip.Uri.generate!(uri)
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report violation in case of ambiguous module deps (different modules binary parts count)" do
"""
defmodule Test do
  def just_an_example do
    Switch.Uri.parse Sip.SomeModule.Uri.generate!(uri)
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report a violation" do
"""
defmodule CredoSampleModule do
  def fun1 do
    ExUnit.Case.something
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should work with __MODULE__" do
"""
defmodule Test do
  alias __MODULE__.SubModule
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # multi alias cases
  #

  @tag needs_elixir: "1.2.0"
  test "it should report violation on impossible additional alias when using multi alias" do
"""
defmodule Test do
  alias Exzmq.{Socket, Tcp}

  def just_an_example do
    Socket.test1
    Exzmq.Socket.test2
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  @tag needs_elixir: "1.2.0"
  test "it should NOT report violation on multi-use alias" do
"""
defmodule Sample.App do
  alias Sample.App.{One, Two}
  def foo, do: {One.one, Two.two}
end

defmodule Sample.App.One do
  def one, do: "One"
end

defmodule Sample.App.Two do
  def two, do: "Two"
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  @tag needs_elixir: "1.2.0"
  test "it should NOT report violation on impossible additional alias when using multi alias" do
"""
defmodule Test do
  alias Exzmq.{Socket, Tcp}

  def just_an_example do
    Socket.test1  # Exzmq.Socket.test
    Tcp.Socket.test2 # Exzmq.Tcp.Socket.test – how can this be further aliased?
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end
end
