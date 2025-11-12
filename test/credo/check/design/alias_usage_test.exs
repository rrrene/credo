defmodule Credo.Check.Design.AliasUsageTest do
  use Credo.Test.Case

  @described_check Credo.Check.Design.AliasUsage

  #
  # single alias cases
  #

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    ~S'''
    defmodule CredoSampleModule do
      alias ExUnit.Case

      def fun1 do
        Case.something

        fun_call().Api.Case

        {:error, reason} = __MODULE__.Sup.start_link(fn() -> :foo end)

        [:faint, filename]    # should not throw an error since
        |> IO.ANSI.format     # IO.ANSI is part of stdlib
        |> Credo.Foo.Code.run # Code is part of the stdlib, aliasing it would
                              # override that `Code`, which you probably don't want
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report if configured not to complain until a certain depth" do
    ~S'''
    defmodule CredoSampleModule do
      alias ExUnit.Case

      def fun1 do
        Credo.Foo.Bar.call
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, if_nested_deeper_than: 3)
    |> refute_issues()
  end

  test "it should NOT report if configured not to complain up to a certain number of calls to the same module" do
    ~S'''
    defmodule CredoSampleModule do
      alias ExUnit.Case

      def fun1 do
        Credo.Foo.Bar.call
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, if_called_more_often_than: 1)
    |> refute_issues()
  end

  test "it should NOT report violation in `@spec`s" do
    ~S'''
    defmodule Sample do
      alias Sample.Foo

      @spec foo(Sample.Foo.t) :: false
      def foo(%Foo{} = _), do: false
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on impossible additional alias" do
    ~S'''
    defmodule Test do
      alias Exzmq.Socket
      alias Exzmq.Tcp

      def just_an_example do
        Socket.test1  # Exzmq.Socket.test
        Tcp.Socket.test2 # Exzmq.Tcp.Socket.test – how can this be further aliased?
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation on impossible additional alias /2" do
    ~S'''
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
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation in case of ambiguous module deps" do
    ~S'''
    defmodule Test do
      def just_an_example do
        Switch.Uri.parse Sip.Uri.generate!(uri)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation in case of ambiguous module deps (different modules binary parts count)" do
    ~S'''
    defmodule Test do
      def just_an_example do
        Switch.Uri.parse Sip.SomeModule.Uri.generate!(uri)
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation when module is not included with only parameter" do
    ~S'''
    defmodule Test do
      def just_an_example do
        Credo.Foo.Bar.call
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, only: ~r/^Other.+$/)
    |> refute_issues()

    ~S'''
    defmodule Test do
      def just_an_example do
        Credo.Foo.Bar.call
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, only: [~r/^Other.+$/])
    |> refute_issues()
  end

  test "it should NOT report violation when module is included in only parameter but is also in excluded_namespaces" do
    ~S'''
    defmodule Test do
      def just_an_example do
        Credo.Foo.Bar.call
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, only: ~r/^Credo.+$/, excluded_namespaces: ["Credo"])
    |> refute_issues()
  end

  test "it should NOT report violation when module is included in only parameter but is also in excluded_lastnames" do
    ~S'''
    defmodule Test do
      def just_an_example do
        Credo.Foo.Bar.call
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, only: ~r/^Credo.+$/, excluded_lastnames: ["Bar"])
    |> refute_issues()
  end

  test "it should NOT report violation when module is covered in excluded_lastnames" do
    ~S'''
    defmodule Test do
      def just_an_example do
        Credo.Foo.Bar.call
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, excluded_lastnames: ["Bar"])
    |> refute_issues()
  end

  test "it should NOT report with __MODULE__" do
    ~S'''
    defmodule Test do
      alias __MODULE__.SubModule
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when module passed as argument" do
    ~S'''
    defmodule Test do
      def fun1 do
        fun2(Credo.Foo.Bar)
      end

      def fun2(mod) do
        mod.call
      end
    end
    '''
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
      def fun1 do
        ExUnit.Case.something
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report if configured to complain start at a certain depth" do
    ~S'''
    defmodule CredoSampleModule do
      alias ExUnit.Case

      def fun1 do
        something
        |> Credo.Foo.Bar.Baz.call
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, if_nested_deeper_than: 3)
    |> assert_issue()
  end

  test "it should report if configured to complain up to a certain number of calls to the same module" do
    ~S'''
    defmodule CredoSampleModule do
      alias ExUnit.Case

      def fun1 do
        Credo.Foo.Bar.call
      end

      def fun1 do
        Credo.Foo.Bar.call
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, if_called_more_often_than: 1)
    |> assert_issues()
  end

  test "it should report violation when module is included in only parameter" do
    ~S'''
    defmodule Test do
      def fun1 do
        Credo.Foo.Bar.call
      end

      def fun1 do
        Other.Foo.call
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, only: ~r/^Credo.+$/)
    |> assert_issue()

    ~S'''
    defmodule Test do
      def fun1 do
        Credo.Foo.Bar.call
      end

      def fun1 do
        Other.Foo.call
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, only: [~r/^Credo.+$/])
    |> assert_issue()
  end

  test "reports violation when module passed as argument" do
    ~S'''
    defmodule Test do
      def fun1 do
        fun2(Credo.Foo.Bar)
      end

      def fun2(mod) do
        mod.call
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check, if_referenced: true)
    |> assert_issue(fn issue ->
      assert issue.trigger == "Credo.Foo.Bar"
    end)
  end

  #
  # multi alias cases
  #

  #
  # cases NOT raising issues
  #

  test "it should NOT report violation on multi-use alias" do
    ~S'''
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
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report violation in quotes" do
    ~S'''
    defmodule Foo.unquote(module).Test do
      alias Exzmq.{Socket, Tcp}
      alias Socket.unquote(stuff).test1
      alias unquote(stuff).Socket.test2
      alias Socket.unquote(stuff)
      alias Exzmq.{Socket, unquote(stuff)}

      def just_an_example do
        Socket.test1  # Exzmq.Socket.test
        Tcp.Socket.test2 # Exzmq.Tcp.Socket.test – how can this be further aliased?
      end

      defmacro just_an_example_as_well do
        quote do
          defmodule Thing.Foo.unquote(module) do
            alias Socket.unquote(module).test1
            alias unquote(module).Socket.test2
            alias unquote(module)
            alias Exzmq.{Socket, unquote(stuff)}
          end
          defmodule unquote(module).Thing.Foo do
            alias Socket.unquote(module).test1
            alias unquote(module).Socket.test2
            alias unquote(module)
            alias Exzmq.{Socket, unquote(stuff)}
          end
        end
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report violation on impossible additional alias when using multi alias" do
    ~S'''
    defmodule Test do
      alias Exzmq.{Socket, Tcp}

      def just_an_example do
        Socket.test1
        Exzmq.Socket.test2
      end
    end
    '''
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert issue.trigger == "Exzmq.Socket"
    end)
  end
end
