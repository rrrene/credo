defmodule Credo.Check.CodeHelper do
  @moduledoc """
  This module contains functions that are used by several checks when dealing
  with the AST.
  """

  alias Credo.Code.Block
  alias Credo.Code.Module
  alias Credo.Code.Parameters

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
end
