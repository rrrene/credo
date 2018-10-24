defmodule Credo.Check.CodeHelper do
  @moduledoc """
  This module contains functions that are used by several checks when dealing
  with the AST.
  """

  alias Credo.Code.Block
  alias Credo.Code.Charlists
  alias Credo.Code.Module
  alias Credo.Code.Parameters
  alias Credo.Code.Scope
  alias Credo.Code.Sigils
  alias Credo.Code.Strings
  alias Credo.Service.SourceFileScopes
  alias Credo.SourceFile

  defdelegate do_block?(ast), to: Block, as: :do_block?
  defdelegate do_block_for!(ast), to: Block, as: :do_block_for!
  defdelegate do_block_for(ast), to: Block, as: :do_block_for
  defdelegate else_block?(ast), to: Block, as: :else_block?
  defdelegate else_block_for!(ast), to: Block, as: :else_block_for!
  defdelegate else_block_for(ast), to: Block, as: :else_block_for

  defdelegate all_blocks_for!(ast), to: Block, as: :all_blocks_for!

  defdelegate calls_in_do_block(ast), to: Block, as: :calls_in_do_block
  defdelegate function_count(ast), to: Module, as: :def_count
  defdelegate def_name(ast), to: Module
  defdelegate parameter_names(ast), to: Parameters, as: :names
  defdelegate parameter_count(ast), to: Parameters, as: :count

  @doc """
  Returns the scope for the given line as a tuple consisting of the call to
  define the scope (`:defmodule`, `:def`, `:defp` or `:defmacro`) and the
  name of the scope.

  Examples:

      {:defmodule, "Foo.Bar"}
      {:def, "Foo.Bar.baz"}
  """
  def scope_for(source_file, line: line_no) do
    source_file
    |> scope_list
    |> Enum.at(line_no - 1)
  end

  @doc """
  Returns all scopes for the given source_file per line of source code as tuple
  consisting of the call to define the scope
  (`:defmodule`, `:def`, `:defp` or `:defmacro`) and the name of the scope.

  Examples:

      [
        {:defmodule, "Foo.Bar"},
        {:def, "Foo.Bar.baz"},
        {:def, "Foo.Bar.baz"},
        {:def, "Foo.Bar.baz"},
        {:def, "Foo.Bar.baz"},
        {:defmodule, "Foo.Bar"}
      ]
  """
  def scope_list(%SourceFile{filename: filename} = source_file) do
    case SourceFileScopes.get(filename) do
      {:ok, value} ->
        value

      :notfound ->
        ast = SourceFile.ast(source_file)
        lines = SourceFile.lines(source_file)

        result =
          Enum.map(lines, fn {line_no, _} ->
            Scope.name(ast, line: line_no)
          end)

        SourceFileScopes.put(filename, result)

        result
    end
  end

  @doc """
  Returns an AST without its metadata.
  """
  def remove_metadata(ast) when is_tuple(ast) do
    update_metadata(ast, fn _ast -> [] end)
  end

  def remove_metadata(ast) do
    ast
    |> List.wrap()
    |> Enum.map(&update_metadata(&1, fn _ast -> [] end))
  end

  defp update_metadata({atom, _meta, list} = ast, fun) when is_list(list) do
    {atom, fun.(ast), Enum.map(list, &update_metadata(&1, fun))}
  end

  defp update_metadata([do: tuple], fun) when is_tuple(tuple) do
    [do: update_metadata(tuple, fun)]
  end

  defp update_metadata([do: tuple, else: tuple2], fun) when is_tuple(tuple) do
    [do: update_metadata(tuple, fun), else: update_metadata(tuple2, fun)]
  end

  defp update_metadata({:do, tuple}, fun) when is_tuple(tuple) do
    {:do, update_metadata(tuple, fun)}
  end

  defp update_metadata({:else, tuple}, fun) when is_tuple(tuple) do
    {:else, update_metadata(tuple, fun)}
  end

  defp update_metadata({atom, _meta, arguments} = ast, fun) do
    {atom, fun.(ast), arguments}
  end

  defp update_metadata(v, fun) when is_list(v), do: Enum.map(v, &update_metadata(&1, fun))

  defp update_metadata(tuple, fun) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Enum.map(&update_metadata(&1, fun))
    |> List.to_tuple()
  end

  defp update_metadata(v, _fun)
       when is_atom(v) or is_binary(v) or is_float(v) or is_integer(v),
       do: v
end
