defmodule Credo.IssueMeta do
  @doc """
  IssueMeta provides helper functions for meta information which a check wants
  to pass to the `issue_for(...)` function, i.e. the current SourceFile and check
  params (by default).
  """

  alias Credo.SourceFile

  def for(source_file, params), do: {__MODULE__, source_file, params}

  def source_file({__MODULE__, source_file, _params}), do: source_file
  def source_file(%SourceFile{} = source_file), do: source_file

  def params({__MODULE__, _source_file, params}), do: params
  def params(%SourceFile{}), do: []
end
