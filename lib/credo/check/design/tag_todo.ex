defmodule Credo.Check.Design.TagTODO do
  use Credo.Check,
    param_defaults: [include_doc: true],
    explanations: [
      check: """
      TODO comments are used to remind yourself of source code related things.

      Example:

          # TODO: move this to a Helper module
          defp fun do
            # ...
          end

      The premise here is that TODO should be dealt with in the near future and
      are therefore reported by Credo.

      Like all `Software Design` issues, this is just advice and might not be
      applicable to your project/situation.
      """,
      params: [
        include_doc: "Set to `true` to also include tags from @doc attributes."
      ]
    ]

  alias Credo.Check.Design.TagHelper

  @tag_name "TODO"

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    include_doc? = Params.get(params, :include_doc, __MODULE__)

    source_file
    |> TagHelper.tags(@tag_name, include_doc?)
    |> Enum.map(&issue_for(issue_meta, &1))
  end

  defp issue_for(issue_meta, {line_no, _line, trigger}) do
    format_issue(
      issue_meta,
      message: "Found a #{@tag_name} tag in a comment: #{trigger}",
      line_no: line_no,
      trigger: trigger
    )
  end
end
