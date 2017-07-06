defmodule Credo.Code.Block do
  @moduledoc """
  This module provides helper functions to analyse blocks, e.g. the block taken
  by the `if` macro.
  """

  @doc """
  Returns the do: block of a given AST node.
  """
  def all_blocks_for!(ast) do
    [
      do_block_for!(ast),
      else_block_for!(ast),
      rescue_block_for!(ast),
      after_block_for!(ast),
    ]
  end

  @doc """
  Returns true if the given `ast` has a do block.
  """
  def do_block?(ast) do
    case do_block_for(ast) do
      {:ok, _block} ->
        true
      nil ->
        false
    end
  end

  @doc """
  Returns the do: block of a given AST node.
  """
  def do_block_for!(ast) do
    case do_block_for(ast) do
      {:ok, block} ->
        block
      nil ->
        nil
    end
  end

  @doc """
  Returns a tuple {:ok, do_block} or nil for a given AST node.
  """
  def do_block_for({_atom, _meta, arguments}) when is_list(arguments) do
    do_block_for(arguments)
  end
  def do_block_for([do: block]) do
    {:ok, block}
  end
  def do_block_for(arguments) when is_list(arguments) do
    Enum.find_value(arguments, &find_keyword(&1, :do))
  end
  def do_block_for(_) do
    nil
  end



  @doc """
  Returns true if the given `ast` has an else block.
  """
  def else_block?(ast) do
    case else_block_for(ast) do
      {:ok, _block} ->
        true
      nil ->
        false
    end
  end

  @doc """
  Returns the `else` block of a given AST node.
  """
  def else_block_for!(ast) do
    case else_block_for(ast) do
      {:ok, block} ->
        block
      nil ->
        nil
    end
  end

  @doc """
  Returns a tuple {:ok, else_block} or nil for a given AST node.
  """
  def else_block_for({_atom, _meta, arguments}) when is_list(arguments) do
    else_block_for(arguments)
  end
  def else_block_for([do: _do_block, else: else_block]) do
    {:ok, else_block}
  end
  def else_block_for(arguments) when is_list(arguments) do
    Enum.find_value(arguments, &find_keyword(&1, :else))
  end
  def else_block_for(_) do
    nil
  end




  @doc """
  Returns true if the given `ast` has an rescue block.
  """
  def rescue_block?(ast) do
    case rescue_block_for(ast) do
      {:ok, _block} ->
        true
      nil ->
        false
    end
  end

  @doc """
  Returns the rescue: block of a given AST node.
  """
  def rescue_block_for!(ast) do
    case rescue_block_for(ast) do
      {:ok, block} ->
        block
      nil ->
        nil
    end
  end

  @doc """
  Returns a tuple {:ok, rescue_block} or nil for a given AST node.
  """
  def rescue_block_for({_atom, _meta, arguments}) when is_list(arguments) do
    rescue_block_for(arguments)
  end
  def rescue_block_for([do: _do_block, rescue: rescue_block]) do
    {:ok, rescue_block}
  end
  def rescue_block_for(arguments) when is_list(arguments) do
    Enum.find_value(arguments, &find_keyword(&1, :rescue))
  end
  def rescue_block_for(_) do
    nil
  end




  @doc """
  Returns true if the given `ast` has an after block.
  """
  def after_block?(ast) do
    case after_block_for(ast) do
      {:ok, _block} ->
        true
      nil ->
        false
    end
  end

  @doc """
  Returns the after: block of a given AST node.
  """
  def after_block_for!(ast) do
    case after_block_for(ast) do
      {:ok, block} ->
        block
      nil ->
        nil
    end
  end

  @doc """
  Returns a tuple {:ok, after_block} or nil for a given AST node.
  """
  def after_block_for({_atom, _meta, arguments}) when is_list(arguments) do
    after_block_for(arguments)
  end
  def after_block_for([do: _do_block, after: after_block]) do
    {:ok, after_block}
  end
  def after_block_for(arguments) when is_list(arguments) do
    Enum.find_value(arguments, &find_keyword(&1, :after))
  end
  def after_block_for(_) do
    nil
  end

  defp find_keyword(list, keyword) when is_list(list) do
    if Keyword.has_key?(list, keyword) do
      {:ok, list[keyword]}
    else
      nil
    end
  end
  defp find_keyword(_, _), do: nil




  @doc """
  Returns the children of the given AST node.
  """
  def calls_in_do_block({_op, _meta, arguments}) do
    arguments
    |> do_block_for!
    |> instructions_for
  end
  def calls_in_do_block(arg) do
    arg
    |> do_block_for!
    |> instructions_for
  end

  defp instructions_for({:__block__, _meta, calls}), do: calls
  defp instructions_for(v) when is_atom(v)
                      or is_tuple(v)
                      or is_binary(v)
                      or is_float(v)
                      or is_integer(v), do: List.wrap(v)
  defp instructions_for(v) when is_list(v), do: [v]
end
