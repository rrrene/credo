defmodule Credo.Check.Warning.UnusedEnumOperation do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: """
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
    ]

  alias Credo.Check.Warning.UnusedOperation

  @checked_module :Enum
  @funs_with_return_value ~w(
      all? any? at chunk chunk chunk_by concat concat count count dedup
      dedup_by drop drop_while empty? fetch fetch! filter filter_map
      find find_index find_value flat_map flat_map_reduce group_by
      intersperse into into join map map_join map_reduce max max_by
      member min min_by min_max min_max_by partition random reduce
      reduce_while reject reverse reverse reverse_slice scan
      scan shuffle slice slice sort sort sort_by split split_while
      sum take take_every take_random take_while to_list uniq uniq_by
      unzip with_index zip
    )a

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    UnusedOperation.run(
      source_file,
      params,
      @checked_module,
      @funs_with_return_value,
      &format_issue/2
    )
  end
end
