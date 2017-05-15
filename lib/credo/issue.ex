defmodule Credo.Issue do
  @doc """
  `Issue` structs represent all issues found during the code analysis.
  """

  defstruct check:        nil,
            category:     nil,
            priority:     0,
            severity:     nil,
            message:      nil,
            filename:     nil,
            line_no:      nil,
            column:       nil,
            exit_status:  0,
            trigger:      nil,  # optional: the String that triggered the check to fail
            meta:         [],   # optional: metadata filled in by the check
            scope:        nil   # optional: the name of the module, macro or
                                #  function where the issue was found

  @type t :: module

end
