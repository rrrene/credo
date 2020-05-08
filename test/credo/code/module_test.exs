defmodule Credo.Code.ModuleTest do
  use Credo.Test.Case

  alias Credo.Code.Module

  doctest Credo.Code.Module

  #
  # attribute
  #

  test "should return the given module attribute" do
    {:ok, ast} =
      """
      defmodule CredoExample do
        @attr_list [:atom1, :atom2]
        @attr_string "This is a String"
        @attr_number 42

        @moduledoc false
      end
      """
      |> Code.string_to_quoted()

    assert [:atom1, :atom2] == Module.attribute(ast, :attr_list)
    assert "This is a String" == Module.attribute(ast, :attr_string)
    assert 42 == Module.attribute(ast, :attr_number)
    assert false == Module.attribute(ast, :moduledoc)
  end

  #
  # def_count
  #

  test "returns the correct parameter counts" do
    {:ok, ast} =
      """
      defmodule Foobar do
      end
      """
      |> Code.string_to_quoted()

    assert 0 == Module.def_count(ast)

    {:ok, ast} =
      """
      defmodule CredoSampleModule do
      def fun1 do
      1
      end
      end
      """
      |> Code.string_to_quoted()

    assert 1 == Module.def_count(ast)

    {:ok, ast} =
      """
      defmodule CredoSampleModule do
      def fun1(nil), do: 1
      def fun1(x), do: fun2 + 1

      defp fun2, do: 42
      defmacro funny_macro, do: quote(true)
      end
      """
      |> Code.string_to_quoted()

    assert 4 == Module.def_count(ast)
  end

  test "returns correct def_count if @def_ops attributes found in source file" do
    {:ok, ast} =
      """
      defmodule CredoSampleModule do
      @doc "some description"

      @def \"""
      Returns a list of `TimeSlice` structs based on the provided `time_slice_selector`.
      \"""

      def fun1(nil), do: 1
      def fun1(x), do: fun2 + 1

      @defp "another strange attribute"
      defp fun2, do: 42

      @defmacro "and another one"
      defmacro funny_macro do
      something = 3
      quote do
        true
      end
      end
      end
      """
      |> Code.string_to_quoted()

    assert 4 == Module.def_count(ast)
  end

  #
  # def_arity
  #

  test "returns correct arity of the function" do
    fun_def_with_arity_0_ast =
      quote do
        def fun0, do: 0
      end

    fun_def_with_arity_1_ast =
      quote do
        defp fun1(x), do: -x
      end

    fun_def_with_arity_2_ast =
      quote do
        def fun2(x, y), do: x * y
      end

    assert Module.def_arity(fun_def_with_arity_0_ast) == 0
    assert Module.def_arity(fun_def_with_arity_1_ast) == 1
    assert Module.def_arity(fun_def_with_arity_2_ast) == 2
  end

  test "returns correct arity of the function even if guard expression specified" do
    fun_ast =
      quote do
        def foobar(x) when is_list(x), do: x
      end

    assert Module.def_arity(fun_ast) == 1
  end

  #
  # def_name
  #

  test ".def_name returns the correct function/macro name" do
    fun0_ast =
      quote do
        def fun0, do: 0
      end

    fun1_ast =
      quote do
        def fun1(x), do: x
      end

    assert :fun0 == Module.def_name(fun0_ast)
    assert :fun1 == Module.def_name(fun1_ast)
  end

  test ".def_name returns the correct function/macro name even if guard expression specified" do
    fun_ast =
      quote do
        def foobar(x) when is_list(x), do: x
      end

    assert :foobar == Module.def_name(fun_ast)
  end

  #
  # def_name_with_op
  #

  test ".def_name_with_op returns the correct function/macro name" do
    fun0_ast =
      quote do
        def fun0, do: 0
      end

    fun1_ast =
      quote do
        defp fun1(x), do: x
      end

    assert {:fun0, :def} == Module.def_name_with_op(fun0_ast)
    assert {:fun1, :defp} == Module.def_name_with_op(fun1_ast)
  end

  #
  # def_names
  #

  test ".def_names returns the correct function/macro names" do
    {:ok, ast} =
      """
      defmodule Foobar do
      end
      """
      |> Code.string_to_quoted()

    assert [] == Module.def_names(ast)

    {:ok, ast} =
      """
      defmodule CredoSampleModule do
      def fun1 do
      1
      end
      end
      """
      |> Code.string_to_quoted()

    assert [:fun1] == Module.def_names(ast)

    {:ok, ast} =
      """
      defmodule CredoSampleModule do
      def fun1(nil), do: 1
      def fun1(x), do: fun2 + 1

      defp fun2, do: 42
      defmacro funny_macro, do: quote(true)
      end
      """
      |> Code.string_to_quoted()

    assert [:fun1, :fun2, :funny_macro] == Module.def_names(ast)
  end

  test "should ignore @def_ops module attributes" do
    {:ok, ast} =
      """
      defmodule CredoSampleModule do
      def fun1(nil), do: 1
      def fun1(x), do: fun2 + 1

      defp fun2, do: 42
      defmacro funny_macro, do: quote(true)
      @defp "fun12"
      @def funX, do: 42
      end
      """
      |> Code.string_to_quoted()

    assert [:fun1, :fun2, :funny_macro] == Module.def_names(ast)
  end

  #
  # def_names_with_op
  #

  test "returns the correct names with defining op" do
    {:ok, ast} =
      """
      defmodule CredoSampleModule do
      def fun1(nil), do: 1
      def fun1(x), do: fun2 + 1

      defp fun2, do: 42
      defmacro funny_macro, do: quote(true)
      @defmacro funny_macro2, do: quote(true)
      end
      """
      |> Code.string_to_quoted()

    expected = [{:fun1, :def}, {:fun2, :defp}, {:funny_macro, :defmacro}]
    assert expected == Module.def_names_with_op(ast)
  end

  test "returns the correct names with defining op and arity" do
    {:ok, ast} =
      """
      defmodule CredoSampleModule do
      def fun1(nil), do: 1
      def fun1(x), do: fun2 + 1

      defp fun2, do: 42
      defmacro funny_macro do
      something = 3
      quote do
        true
      end
      end
      end
      """
      |> Code.string_to_quoted()

    expected0 = [{:fun2, :defp}, {:funny_macro, :defmacro}]
    assert expected0 == Module.def_names_with_op(ast, 0)

    expected1 = [{:fun1, :def}]
    assert expected1 == Module.def_names_with_op(ast, 1)
  end

  #
  # modules
  #

  test "returns the list of modules used in a given module source code when using multi alias" do
    {:ok, ast} =
      """
      defmodule Test do
      alias Exzmq.{Socket, Tcp}

      def just_an_example do
      Socket.test1
      Exzmq.Socket.test2
      end
      end
      """
      |> Code.string_to_quoted()

    expected = ["Socket", "Exzmq.Socket"]
    assert expected == Module.modules(ast)
  end

  test "returns the list of modules used in a given module source code" do
    {:ok, ast} =
      """
      defmodule Test do
      alias Exzmq.Socket
      alias Exzmq.Tcp

      def just_an_example do
      Socket.test1
      Exzmq.Socket.test2
      end
      end
      """
      |> Code.string_to_quoted()

    expected = ["Socket", "Exzmq.Socket"]
    assert expected == Module.modules(ast)
  end

  #
  # aliases
  #

  test "returns the list of aliases used in a given module source code when using multi alias" do
    {:ok, ast} =
      """
      defmodule Test do
      alias Exzmq.{Socket, Tcp}

      def just_an_example do
      Socket.test1
      Exzmq.Socket.test2
      end
      end
      """
      |> Code.string_to_quoted()

    expected = ["Exzmq.Socket", "Exzmq.Tcp"]
    assert expected == Module.aliases(ast)
  end

  test "returns the list of aliases used in a given module source code" do
    {:ok, ast} =
      """
      defmodule Test do
      alias Exzmq.Socket
      alias Exzmq.Tcp
      alias Some.Very.Long.Name

      def just_an_example do
      Socket.test1
      Exzmq.Socket.test2
      end
      end
      """
      |> Code.string_to_quoted()

    expected = ["Exzmq.Socket", "Exzmq.Tcp", "Some.Very.Long.Name"]
    assert expected == Module.aliases(ast)
  end

  test "returns a default string when nested defmodule name cannot be found when Module.name is called" do
    nested_module =
      quote do
        defmodule Credo.Sample1 do
          testing_list = ["One", "Two", "Three"]

          testing_list
          |> Enum.each(fn test_item ->
            defmodule test_item do
            end
          end)
        end
      end

    {:defmodule, _, [{:__aliases__, _, _}, inner_module]} = nested_module

    assert Module.name(nested_module) === "Credo.Sample1"
    assert Module.name(inner_module) === "<Unknown Module Name>"
  end

  test "returns the name of the module when Module.name is called" do
    module =
      quote do
        defmodule CredoTestParent.AnotherModule do
        end
      end

    assert Module.name(module) === "CredoTestParent.AnotherModule"
  end

  describe "analyze" do
    test "recognizes shortdoc" do
      assert analyze(~s/@shortdoc "shortdoc"/) == [{Test, [shortdoc: [line: 2, column: 3]]}]
    end

    test "recognizes moduledoc" do
      assert analyze(~s/@moduledoc "moduledoc"/) == [{Test, [moduledoc: [line: 2, column: 3]]}]
    end

    test "recognizes @behaviour" do
      assert analyze(~s/@behaviour GenServer/) == [{Test, [behaviour: [line: 2, column: 3]]}]
    end

    test "recognizes use" do
      assert analyze(~s/use GenServer/) == [{Test, [use: [line: 2, column: 3]]}]
    end

    test "recognizes alias" do
      assert analyze(~s/alias GenServer/) == [{Test, [alias: [line: 2, column: 3]]}]
    end

    test "recognizes import" do
      assert analyze(~s/import GenServer/) == [{Test, [import: [line: 2, column: 3]]}]
    end

    test "recognizes require" do
      assert analyze(~s/require GenServer/) == [{Test, [require: [line: 2, column: 3]]}]
    end

    test "recognizes module attribute" do
      assert analyze(~s/@mod_attr 1/) == [{Test, [module_attribute: [line: 2, column: 3]]}]
    end

    test "recognizes struct definition" do
      assert analyze(~s/defstruct [:foo]/) == [{Test, [defstruct: [line: 2, column: 3]]}]
    end

    test "recognizes opaque type" do
      assert analyze(~s/@opaque x :: any/) == [{Test, [opaque: [line: 2, column: 3]]}]
    end

    test "recognizes type" do
      assert analyze(~s/@type x :: any/) == [{Test, [type: [line: 2, column: 3]]}]
    end

    test "recognizes typep" do
      assert analyze(~s/@typep x :: any/) == [{Test, [typep: [line: 2, column: 3]]}]
    end

    test "recognizes callback" do
      assert analyze(~s/@callback c() :: any/) == [{Test, [callback: [line: 2, column: 3]]}]
    end

    test "recognizes macrocallback" do
      assert analyze(~s/@macrocallback c() :: any/) ==
               [{Test, [macrocallback: [line: 2, column: 3]]}]
    end

    test "recognizes optional_callbacks" do
      assert analyze(~s/@optional_callbacks [c: 0]/) ==
               [{Test, [optional_callbacks: [line: 2, column: 3]]}]
    end

    test "recognizes defguard" do
      assert analyze(~s/defguard x, do: true/) == [{Test, [public_guard: [line: 2, column: 3]]}]
    end

    test "recognizes defguardp" do
      assert analyze(~s/defguardp x, do: true/) == [{Test, [private_guard: [line: 2, column: 3]]}]
    end

    test "interprets defguard marked with @doc false as private guard" do
      assert analyze(~s/@doc false\ndefguard x, do: true/) ==
               [{Test, [private_guard: [line: 3, column: 3]]}]
    end

    test "recognizes defmacro" do
      assert analyze(~s/defmacro x, do: true/) == [{Test, [public_macro: [line: 2, column: 3]]}]
    end

    test "recognizes defmacrop" do
      assert analyze(~s/defmacrop x, do: true/) == [{Test, [private_macro: [line: 2, column: 3]]}]
    end

    test "interprets defmacro marked with @doc false as private macro" do
      assert analyze(~s/@doc false\ndefmacro x, do: true/) ==
               [{Test, [private_macro: [line: 3, column: 3]]}]
    end

    test "interprets defmacro marked with @impl as callback macro" do
      assert analyze(~s/@impl true\ndefmacro x, do: true/) ==
               [{Test, [callback_macro: [line: 3, column: 3]]}]
    end

    test "recognizes def" do
      assert analyze(~s/def x, do: true/) == [{Test, [public_fun: [line: 2, column: 3]]}]
    end

    test "recognizes defp" do
      assert analyze(~s/defp x, do: true/) == [{Test, [private_fun: [line: 2, column: 3]]}]
    end

    test "interprets def marked with @doc false as private fun" do
      assert analyze(~s/@doc false\ndef x, do: true/) ==
               [{Test, [private_fun: [line: 3, column: 3]]}]
    end

    test "interprets def marked with @impl as a callback fun" do
      assert analyze(~s/@impl true\ndef x, do: true/) ==
               [{Test, [callback_fun: [line: 3, column: 3]]}]
    end

    test "deduplicates multiclauses" do
      assert analyze("""
             def a(1), do: true
             def a(2), do: false

             @impl true
             def b(1), do: true
             def b(2), do: false

             @doc false
             def c(1), do: true
             def c(2), do: false

             defp d(1), do: true
             defp d(2), do: false
             """) == [
               {Test,
                public_fun: [line: 2, column: 3],
                callback_fun: [line: 6, column: 3],
                private_fun: [line: 10, column: 3],
                private_fun: [line: 13, column: 3]}
             ]
    end

    test "handles multiple modules" do
      full_source =
        """
        defmodule Foo do
          @shortdoc "foo"
        end

        defmodule Bar do
          @moduledoc "bar"
        end
        """
        |> to_string()

      {:ok, ast} = Credo.Code.ast(full_source)

      assert Module.analyze(ast) ==
               [
                 {Foo, [shortdoc: [line: 2, column: 3]]},
                 {Bar, [moduledoc: [line: 6, column: 3]]}
               ]
    end

    test "handles nested modules" do
      full_source =
        """
        defmodule Foo do
          @shortdoc "foo"

          defmodule Bar do
            @moduledoc "bar"

            defmodule Baz do
              @behaviour GenServer
            end
          end

          use GenServer
        end
        """
        |> to_string()

      {:ok, ast} = Credo.Code.ast(full_source)

      assert Module.analyze(ast) ==
               [
                 {Foo,
                  [
                    shortdoc: [line: 2, column: 3],
                    module: [line: 4, column: 3],
                    use: [line: 12, column: 3]
                  ]},
                 {Foo.Bar, [moduledoc: [line: 5, column: 5], module: [line: 7, column: 5]]},
                 {Foo.Bar.Baz, [behaviour: [line: 8, column: 7]]}
               ]
    end

    test "handles dynamic module names" do
      full_source =
        """
        module = Foo

        defmodule module do
          defmodule __MODULE__.Bar do
          end
        end

        module = Bar

        defmodule module do
          defmodule __MODULE__.Qux do
          end
        end
        """
        |> to_string()

      {:ok, ast} = Credo.Code.ast(full_source)

      assert Module.analyze(ast) == [
               {Unknown, [module: [line: 4, column: 3]]},
               {Unknown.Unknown.Bar, []},
               {Unknown, [module: [line: 11, column: 3]]},
               {Unknown.Unknown.Qux, []}
             ]
    end

    defp analyze(fragment) do
      full_source =
        "defmodule Test do #{fragment} end"
        |> Code.format_string!()
        |> to_string()

      {:ok, ast} = Credo.Code.ast(full_source)
      Module.analyze(ast)
    end
  end
end
