defmodule Credo.Check.Warning.SpecWithStructTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.SpecWithStruct

  @my_struct_module ~S'''
  defmodule MyApp.MyStruct do
    @type t :: %__MODULE__{id: integer, name: String.t()}
    defstruct [:id, :name]
  end
  '''

  @a_struct_module ~S'''
  defmodule AStruct do
    @type t :: %__MODULE__{a: any}
    defstruct [:a]
  end
  '''

  #
  # cases NOT raising issues
  #

  test "it should NOT report an issue if t() is used in a spec" do
    [
      ~S'''
      defmodule CorrectUsage do
        @spec f(MyApp.MyStruct.t()) :: any
        def f(_) do
          "yay"
        end

        @spec g(any, AStruct.t()) :: MyApp.MyStruct.t()
        def g(_, _) do
          "yay"
        end
      end
      ''',
      @my_struct_module,
      @a_struct_module
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report an issue for functions, macros, or variables named spec" do
    [
      ~S'''
      defmodule IgnoredFunction do
        def spec(%AStruct{}) do
          "okay"
        end

        def spec(arg) when arg == %AStruct{} do
          arg
        end
      end
      ''',
      ~S'''
      defmodule IgnoredMacro do
        defmacro spec(arg) do
          arg
        end
      end
      ''',
      ~S'''
      defmodule IgnoredVariable do
        def spec(id) do
          spec = %AStruct{id: id}
        end
      end
      ''',
      @a_struct_module
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report an issue if a struct is used as a parameter in a spec" do
    [
      ~S'''
      defmodule Offender do
        @spec f(any, %MyApp.MyStruct{}, any) :: any
        def f(_, _, _) do
          "oops"
        end
      end
      ''',
      @my_struct_module
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue(%{
      line_no: 2,
      column: 16,
      trigger: "%MyApp.MyStruct{",
      message: "Struct %MyApp.MyStruct{} found in `@spec`."
    })
  end

  test "it should report an issue if a struct is used as a return value in a spec" do
    [
      ~S'''
      defmodule Offender do
        @spec f() :: %AStruct{}
        def f do
          "oops"
        end
      end
      ''',
      @a_struct_module
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 2, column: 16, trigger: "%AStruct{"})
  end

  test "it should report an issue if a struct is part of a union in a spec" do
    [
      ~S'''
      defmodule Offender do
        alias MyApp.MyStruct, as: MS
        @spec f(String.t() | %MS{} | integer) :: any
        def f(_) do
          "oops"
        end
      end
      ''',
      @my_struct_module
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 3, column: 24})
  end

  test "it should report an issue if a struct is used as an argument in a spec" do
    [
      ~S'''
      defmodule Offender do
        alias MyApp.MyStruct
        @spec f(arg) :: any when arg: %MyStruct{}
        def f(_) do
          "oops"
        end
      end
      ''',
      @my_struct_module
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 3, column: 33})
  end

  test "it should report an issue if a struct has an argument name in a spec" do
    [
      ~S'''
      defmodule Offender do
        @spec f(my_struct :: %MyApp.MyStruct{}) :: any
        def f(_) do
          "oops"
        end
      end
      ''',
      @my_struct_module
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 2, column: 24})
  end

  test "it should report multiple issues in separate specs" do
    [
      ~S'''
      defmodule Offender do
        @spec f(my_struct :: %MyApp.MyStruct{}) :: any
        def f(_) do
          "oops"
        end

        @spec g(a_struct :: %AStruct{}) :: any
        def g(_) do
          "oops"
        end
      end
      ''',
      @my_struct_module,
      @a_struct_module
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report multiple issues in a single spec" do
    [
      ~S'''
      defmodule Offender do
        @spec f(a_struct :: %AStruct{}, my_struct :: %MyApp.MyStruct{}) :: any
        def f(_, _) do
          "oops"
        end
      end
      ''',
      @my_struct_module,
      @a_struct_module
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issues()
  end
end
