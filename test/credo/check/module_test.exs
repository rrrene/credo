defmodule Credo.Check.ConfigCommentFinderTest do
  use ExUnit.Case, async: true
  alias Credo.Check.Module

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
