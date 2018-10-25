defmodule Credo.Check.ConfigComment do
  @moduledoc """
  `ConfigComment` structs represent comments which follow control Credo's behaviour.

  The following comments are supported:

      # credo:disable-for-this-file
      # credo:disable-for-next-line
      # credo:disable-for-previous-line
      # credo:disable-for-lines:<number>

  """

  @instruction_disable_file "disable-for-this-file"
  @instruction_disable_next_line "disable-for-next-line"
  @instruction_disable_previous_line "disable-for-previous-line"
  @instruction_disable_lines "disable-for-lines"

  alias Credo.Issue

  defstruct line_no: nil,
            line_no_end: nil,
            instruction: nil,
            params: nil

  @doc "Returns a `ConfigComment` struct based on the given parameters."
  def new(instruction, param_string, line_no)

  def new("#{@instruction_disable_lines}:" <> line_count, param_string, line_no) do
    line_count = String.to_integer(line_count)

    params =
      param_string
      |> value_for()
      |> List.wrap()

    if line_count >= 0 do
      %__MODULE__{
        line_no: line_no,
        line_no_end: line_no + line_count,
        instruction: @instruction_disable_lines,
        params: params
      }
    else
      %__MODULE__{
        line_no: line_no + line_count,
        line_no_end: line_no,
        instruction: @instruction_disable_lines,
        params: params
      }
    end
  end

  def new(instruction, param_string, line_no) do
    %__MODULE__{
      line_no: line_no,
      instruction: instruction,
      params: param_string |> value_for() |> List.wrap()
    }
  end

  @doc "Returns `true` if the given `issue` should be ignored based on the given `config_comment`"
  def ignores_issue?(config_comment, issue)

  def ignores_issue?(
        %__MODULE__{instruction: @instruction_disable_file, params: params},
        %Issue{} = issue
      ) do
    params_ignore_issue?(params, issue)
  end

  def ignores_issue?(
        %__MODULE__{
          instruction: @instruction_disable_next_line,
          line_no: line_no,
          params: params
        },
        %Issue{line_no: line_no_issue} = issue
      )
      when line_no_issue == line_no + 1 do
    params_ignore_issue?(params, issue)
  end

  def ignores_issue?(
        %__MODULE__{
          instruction: @instruction_disable_previous_line,
          line_no: line_no,
          params: params
        },
        %Issue{line_no: line_no_issue} = issue
      )
      when line_no_issue == line_no - 1 do
    params_ignore_issue?(params, issue)
  end

  def ignores_issue?(
        %__MODULE__{
          instruction: @instruction_disable_lines,
          line_no: line_no_start,
          line_no_end: line_no_end,
          params: params
        },
        %Issue{line_no: line_no_issue} = issue
      )
      when line_no_issue >= line_no_start and line_no_issue <= line_no_end do
    params_ignore_issue?(params, issue)
  end

  def ignores_issue?(_, _) do
    false
  end

  #

  defp params_ignore_issue?([], _issue) do
    true
  end

  defp params_ignore_issue?(params, issue) when is_list(params) do
    Enum.any?(params, &check_tuple_ignores_issue?(&1, issue))
  end

  defp check_tuple_ignores_issue?(check_or_regex, issue) do
    if Regex.regex?(check_or_regex) do
      issue.check
      |> to_string
      |> String.match?(check_or_regex)
    else
      issue.check == check_or_regex
    end
  end

  defp value_for(""), do: nil

  defp value_for(param_string) do
    if regex_value?(param_string) do
      param_string
      |> String.slice(1..-2)
      |> Regex.compile!("i")
    else
      String.to_atom("Elixir.#{param_string}")
    end
  end

  defp regex_value?(param_string), do: param_string =~ ~r'^/.+/$'
end
