defmodule Credo.Issue do
  defstruct rule:     nil,
            category: nil,
            message:  nil,
            trigger:  nil,
            line:     nil,
            column:   nil
end
