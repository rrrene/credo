defmodule Credo.IssueMeta do
  @moduledoc """
  IssueMeta provides helper functions for meta information which a check wants
  to pass to the `issue_for(...)` function, i.e. the current SourceFile and check
  params (by default).
  """

  @type t :: {__MODULE__, Credo.SourceFile.t(), Keyword.t()}

  alias Credo.SourceFile

  @doc "Returns an issue meta tuple for the given `source_file` and `check_params`."
  def for(source_file, check_params) do
    {__MODULE__, source_file, check_params}
  end

  @doc "Returns the source file for the given `issue_meta`."
  def source_file(issue_meta)

  def source_file({__MODULE__, source_file, _params}) do
    source_file
  end

  def source_file(%SourceFile{} = source_file) do
    source_file
  end

  @doc "Returns the check params for the given `issue_meta`."
  def params(issue_meta)

  def params({__MODULE__, _source_file, check_params}), do: check_params
  def params(%SourceFile{}), do: []
end
