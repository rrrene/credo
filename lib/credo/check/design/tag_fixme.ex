defmodule Credo.Check.Design.TagFIXME do
  @moduledoc """
  FIXME comments are used to indicate places where source code needs fixing.

  Example:

      # FIXME: this does no longer work, research new API url
      defp fun do
        # ...
      end

  The premise here is that FIXME should indeed be fixed as soon as possible and
  are therefore reported by Credo.

  Like all `Software Design` issues, this is just advice and might not be
  applicable to your project/situation.
  """

  @explanation [check: @moduledoc]
  @tag_name "FIXME"

  alias Credo.Check.Design.TagHelper

  use Credo.Check, base_priority: :high

  def run(%SourceFile{source: source} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source
    |> TagHelper.tags(@tag_name)
    |> Enum.map(&issue_for(issue_meta, &1))
  end

  defp issue_for(issue_meta, {line_no, _line, trigger}) do
    format_issue issue_meta,
      message: "Found a #{@tag_name} tag in a comment: #{trigger}",
      line_no: line_no,
      trigger: trigger
  end

end
