defmodule Credo.Check.Design.AliasUsageTest do
  use Credo.TestHelper

  @described_check Credo.Check.Design.AliasUsage

  #
  # single alias cases
  #

  #
  # cases NOT raising issues
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

  test "it should NOT report if configured not to complain until a certain depth" do
"""
defmodule CredoSampleModule do
  alias ExUnit.Case

  def fun1 do
    Credo.Foo.Bar.call
  end
end
""" |> to_source_file
    |> refute_issues(@described_check, if_nested_deeper_than: 3)
  end

  test "it should NOT report if configured not to complain up to a certain number of calls to the same module" do
"""
defmodule CredoSampleModule do
  alias ExUnit.Case

  def fun1 do
    Credo.Foo.Bar.call
  end
end
""" |> to_source_file
    |> refute_issues(@described_check, if_called_more_often_than: 1)
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

  test "it should NOT report violation on impossible additional alias /2" do
"""
defmodule Test do
  # Modules are
  #
  # - AppName.Foo.User
  # - AppName.Bar.User
  #
  alias AppName.Foo.User

  def foo do
    User.some_fun() # resolves to AppName.Foo.User
  end

  def bar do
    AppName.Bar.User.some_other_fun()
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

  test "it should work with __MODULE__" do
"""
defmodule Test do
  alias __MODULE__.SubModule
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

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

  test "it should report even when allowing shorter alias" do
"""
defmodule CredoSampleModule do
  alias ExUnit.Case

  def fun1 do
    something
    |> Credo.Foo.Bar.Baz.call
  end
end
""" |> to_source_file
    |> assert_issue(@described_check, allow_shorter_alias: true)
  end

  test "it should report if configured to complain start at a certain depth" do
"""
defmodule CredoSampleModule do
  alias ExUnit.Case

  def fun1 do
    something
    |> Credo.Foo.Bar.Baz.call
  end
end
""" |> to_source_file
    |> assert_issue(@described_check, if_nested_deeper_than: 3)
  end

  test "it should report if configured to complain up to a certain number of calls to the same module" do
"""
defmodule CredoSampleModule do
  alias ExUnit.Case

  def fun1 do
    Credo.Foo.Bar.call
  end

  def fun1 do
    Credo.Foo.Bar.call
  end
end
""" |> to_source_file
    |> assert_issues(@described_check, if_called_more_often_than: 1)
  end

  #
  # multi alias cases
  #

  #
  # cases NOT raising issues
  #

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

  test "it should NOT report when allowing shorter alias" do
"""
defmodule CredoSampleModule do
  alias ExUnit.Case
  alias Credo.Foo

  def fun1 do
    something
    |> Foo.Bar.Baz.call
  end
end
""" |> to_source_file
    |> refute_issues(@described_check, allow_shorter_alias: true)
  end

  #
  # cases raising issues
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

end
