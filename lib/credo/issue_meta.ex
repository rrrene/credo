defmodule Credo.IssueMeta do
  @doc """
  IssueMeta provides helper functions for meta information which a check wants
  to pass to the `issue_for(...)` function, i.e. the current SourceFile and check
  params (by default).
  """

  @type t :: module

  alias Credo.SourceFile

  def for(current_source_file, check_params) do
    {__MODULE__, current_source_file, check_params}
  end

  def source_file({__MODULE__, current_source_file, _params}) do
    current_source_file
  end
  def source_file(%SourceFile{} = current_source_file) do
    current_source_file
  end

  def params({__MODULE__, _source_file, check_params}), do: check_params
  def params(%SourceFile{}), do: []
end
