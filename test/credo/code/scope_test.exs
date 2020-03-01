defmodule Credo.Code.ScopeTest do
  use Credo.Test.Case

  alias Credo.Code.Scope

  test "it should report the correct scope" do
    {:ok, ast} =
      """
      defmodule Credo.Sample do
        @test_attribute :foo

        def foobar(parameter1, parameter2) do
          String.split(parameter1) + parameter2
        end

        defmodule InlineModule do
          def foobar(v) when is_atom(v) do
            {:ok} = File.read
          end
        end
      end

      defmodule OtherModule do
        defmacro foo do
          {:ok} = File.read
        end

        test do
          something_during_compile_time___probably_magic!
        end

        defp bar do
          :ok
        end
      end
      """
      |> Code.string_to_quoted()

    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 1)
    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 2)
    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 3)
    assert {:def, "Credo.Sample.foobar"} == Scope.name(ast, line: 5)

    assert {:def, "Credo.Sample.InlineModule.foobar"} == Scope.name(ast, line: 10)

    assert {:defmacro, "OtherModule.foo"} == Scope.name(ast, line: 17)
    assert {:defmodule, "OtherModule"} == Scope.name(ast, line: 22)
    assert {:defmodule, "OtherModule"} == Scope.name(ast, line: 23)
    assert {:defp, "OtherModule.bar"} == Scope.name(ast, line: 25)
  end

  test "it should report the correct scope even if the file does not start with defmodule" do
    {:ok, ast} =
      """
      if some_compile_time_check do
        defmodule Credo.Sample do
          @test_attribute :foo

          def foobar(parameter1, parameter2) do
            String.split(parameter1) + parameter2
          end

          defmodule InlineModule do
            def foobar(v) when is_atom(v) do
              {:ok} = File.read
            end
          end
        end

        defmodule OtherModule do
          defmacro foo do
            {:ok} = File.read
          end

          defp bar do
            :ok
          end
        end
      end
      """
      |> Code.string_to_quoted()

    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 2)
    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 3)
    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 4)
    assert {:def, "Credo.Sample.foobar"} == Scope.name(ast, line: 6)

    assert {:def, "Credo.Sample.InlineModule.foobar"} == Scope.name(ast, line: 11)

    assert {:defmacro, "OtherModule.foo"} == Scope.name(ast, line: 18)
    assert {:defp, "OtherModule.bar"} == Scope.name(ast, line: 22)
  end

  @tag :to_be_implemented
  test "it should report the correct scope (pedanticly)" do
    {:ok, ast} =
      """
      defmodule Credo.Sample do
        @test_attribute :foo

        def foobar(parameter1, parameter2) do
          String.split(parameter1) + parameter2
        end

        defmodule InlineModule do
          def foobar(v) when is_atom(v) do
            {:ok} = File.read
          end
        end
      end

      defmodule OtherModule do
        defmacro foo do
          {:ok} = File.read
        end

        defp bar do
          :ok
        end
      end
      """
      |> Code.string_to_quoted()

    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 1)
    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 2)
    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 3)
    assert {:def, "Credo.Sample.foobar"} == Scope.name(ast, line: 4)
    assert {:def, "Credo.Sample.foobar"} == Scope.name(ast, line: 5)
    assert {:def, "Credo.Sample.foobar"} == Scope.name(ast, line: 6)
    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 7)
    assert {:defmodule, "Credo.Sample.InlineModule"} == Scope.name(ast, line: 8)

    assert {:def, "Credo.Sample.InlineModule.foobar"} == Scope.name(ast, line: 9)

    assert {:def, "Credo.Sample.InlineModule.foobar"} == Scope.name(ast, line: 10)

    assert {:def, "Credo.Sample.InlineModule.foobar"} == Scope.name(ast, line: 11)

    assert {:defmodule, "Credo.Sample.InlineModule"} == Scope.name(ast, line: 12)

    assert {:defmodule, "Credo.Sample"} == Scope.name(ast, line: 13)
    assert {nil, ""} == Scope.name(ast, line: 14)

    assert {:defmodule, "OtherModule"} == Scope.name(ast, line: 15)
    assert {:defmacro, "OtherModule.foo"} == Scope.name(ast, line: 16)
    assert {:defmacro, "OtherModule.foo"} == Scope.name(ast, line: 17)
    assert {:defmacro, "OtherModule.foo"} == Scope.name(ast, line: 18)
    assert {:defmodule, "OtherModule"} == Scope.name(ast, line: 19)
    assert {:defp, "OtherModule.bar"} == Scope.name(ast, line: 20)
    assert {:defp, "OtherModule.bar"} == Scope.name(ast, line: 21)
    assert {:defp, "OtherModule.bar"} == Scope.name(ast, line: 22)
    assert {:defmodule, "OtherModule"} == Scope.name(ast, line: 23)
  end

  test "it should report the correct scope even outside of modules" do
    {:ok, ast} =
      """
      defmodule Bar do
      end

      require Foo
      IO.puts Foo.message
      """
      |> Code.string_to_quoted()

    assert {:defmodule, "Bar"} == Scope.name(ast, line: 1)
    assert {nil, ""} == Scope.name(ast, line: 5)
  end

  test "it should report the correct scope even outside of modules 2" do
    {:ok, ast} =
      """
      [my_app: [key: :value]]
      """
      |> Code.string_to_quoted()

    assert {nil, ""} == Scope.name(ast, line: 1)
  end

  test "it should report the correct mod_name" do
    assert "Credo.Sample" == Scope.mod_name("Credo.Sample.foobar")
    assert "Credo.Sample" == Scope.mod_name("Credo.Sample")
  end

  test "it should give a list of scope names" do
    {:ok, ast} =
      """
      # some_file.ex
      defmodule AliasTest do
        def test do
          [
            :a,
            :a,
            :a,
            :a,
            :a,
            :a,
            :a,
            :a,
            :a,
            :a,
            :a,
            :a,
            :a,
            :a
          ]

          Any.Thing.test()
        end
      end
      """
      |> Code.string_to_quoted()

    assert {:def, "AliasTest.test"} == Scope.name(ast, line: 21)
  end
end
