defmodule Credo.Check.CodeHelper do
  @moduledoc """
  This module contains functions that are used by several checks when dealing
  with the AST.
  """

  alias Credo.Code.Block
  alias Credo.Code.Parameters
  alias Credo.Code.Module
  alias Credo.Code.Scope
  alias Credo.Code.Sigils
  alias Credo.Code.Strings
  alias Credo.Service.SourceFileScopes
  alias Credo.Service.SourceFileCodeOnly
  alias Credo.Service.SourceFileWithoutStringAndSigils
  alias Credo.SourceFile

  @def_ops [:def, :defp, :defmacro]

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
  def scope_for(source_file, [line: line_no]) do
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
  def scope_list(%SourceFile{filename: filename, ast: ast, lines: lines}) do
    case SourceFileScopes.get(filename) do
      {:ok, value} ->
        value
      :notfound ->
        result =
          lines
          |> Enum.map(fn({line_no, _}) ->
              Scope.name(ast, line: line_no)
            end)
        SourceFileScopes.put(filename, result)
        result
    end
  end

  @doc """
  Returns true if the given `child` AST node is part of the larger
  `parent` AST node.
  """
  def contains_child?(parent, child) do
    Credo.Code.prewalk(parent, &find_child(&1, &2, child), false)
  end

  defp find_child(parent, acc, child), do: {parent, acc || parent == child}

  @doc """
  Takes a SourceFile and returns its source code stripped of all Strings, Sigils
  and code comments.
  """
  def clean_strings_sigils_and_comments(%SourceFile{filename: filename, source: source}) do
    case SourceFileCodeOnly.get(filename) do
      {:ok, value} ->
        value
      :notfound ->
        result = clean_strings_sigils_and_comments(source)
        SourceFileCodeOnly.put(filename, result)
        result
    end
  end
  def clean_strings_sigils_and_comments(source) do
    source
    |> Sigils.replace_with_spaces("")
    |> Strings.replace_with_spaces
    |> String.replace(~r/([^\?])#.+/, "\\1")
  end

  @doc """
  Takes a SourceFile and returns its source code stripped of all Strings and
  Sigils.
  """
  def clean_strings_and_sigils(%SourceFile{filename: filename, source: source}) do
    case SourceFileWithoutStringAndSigils.get(filename) do
      {:ok, value} ->
        value
      :notfound ->
        result = clean_strings_and_sigils(source)
        SourceFileWithoutStringAndSigils.put(filename, result)
        result
    end
  end
  def clean_strings_and_sigils(source) do
    source
    |> Sigils.replace_with_spaces
    |> Strings.replace_with_spaces
  end


  @doc """
  Returns an AST without its metadata.
  """
  def remove_metadata(ast) when is_tuple(ast) do
    clean_node(ast)
  end
  def remove_metadata(ast) do
    ast
    |> List.wrap
    |> Enum.map(&clean_node/1)
  end

  defp clean_node({atom, _meta, list}) when is_list(list) do
    {atom, [], Enum.map(list, &clean_node/1)}
  end
  defp clean_node([do: tuple]) when is_tuple(tuple) do
    [do: clean_node(tuple)]
  end
  defp clean_node([do: tuple, else: tuple2]) when is_tuple(tuple) do
    [do: clean_node(tuple), else: clean_node(tuple2)]
  end
  defp clean_node({:do, tuple}) when is_tuple(tuple) do
    {:do, clean_node(tuple)}
  end
  defp clean_node({:else, tuple}) when is_tuple(tuple) do
    {:else, clean_node(tuple)}
  end
  defp clean_node({atom, _meta, arguments}) do
    {atom, [], arguments}
  end
  defp clean_node(v) when is_list(v), do: Enum.map(v, &clean_node/1)
  defp clean_node(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list
    |> Enum.map(&clean_node/1)
    |> List.to_tuple
  end
  defp clean_node(v) when is_atom(v)
                      or is_binary(v)
                      or is_boolean(v)
                      or is_float(v)
                      or is_integer(v)
                      or is_nil(v), do: v
end
