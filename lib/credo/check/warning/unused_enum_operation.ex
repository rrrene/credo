defmodule Credo.Check.Warning.UnusedEnumOperation do
  @moduledoc """
  With the exception of `Enum.each/2`, the result of a call to the
  Enum module's functions has to be used.

  While this is correct ...

      def prepend_my_username(my_username, usernames) do
        valid_usernames = Enum.reject(usernames, &is_nil/1)

        [my_username] ++ valid_usernames
      end

  ... we forgot to save the downcased username in this example:

      # This is bad because it does not modify the usernames variable!

      def prepend_my_username(my_username, usernames) do
        Enum.reject(usernames, &is_nil/1)

        [my_username] ++ valid_usernames
      end

  Since Elixir variables are immutable, Enum operations never work on the
  variable you pass in, but return a new variable which has to be used somehow
  (the exception being `Enum.each/2` which iterates a list and returns `:ok`).
  """

  @explanation [check: @moduledoc]
  @checked_module :Enum
  @funs_with_return_value ~w(
    all any at chunk chunk chunk_by concat concat count count dedup
    dedup_by drop drop_while empty fetch fetch filter filter_map
    find find_index find_value flat_map flat_map_reduce group_by
    intersperse into into join map map_join map_reduce max max_by
    member min min_by min_max min_max_by partition random reduce
    reduce reduce_while reject reverse reverse reverse_slice scan
    scan shuffle slice slice sort sort sort_by split split_while
    sum take take_every take_random take_while to_list uniq uniq_by
    unzip with_index zip
  )a

  alias Credo.Check.Warning.UnusedFunctionReturnHelper

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    all_unused_calls =
      UnusedFunctionReturnHelper.find_unused_calls(
        source_file, params, [@checked_module], @funs_with_return_value
      )

    Enum.reduce(all_unused_calls, [], fn(invalid_call, issues) ->
      {_, meta, _} = invalid_call

      trigger =
        invalid_call
        |> Macro.to_string
        |> String.split("(")
        |> List.first

      issues ++ [issue_for(issue_meta, meta[:line], trigger)]
    end)
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "There should be no unused return values for #{trigger}().",
      trigger: trigger,
      line_no: line_no
  end
end
