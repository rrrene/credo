defmodule Credo.Check.Warning.UnusedMapOperation do
  use Credo.Check,
    id: "EX5028",
    base_priority: :high,
    explanations: [
      check: """
      The result of a call to the Map module's functions has to be used.

      While this is correct ...

          def clean_and_verify_options!(map) do
            map = Map.delete(map, :debug)

            if Enum.length(map) == 0, do: raise "OMG!!!1"

            map
          end

      ... we forgot to save the result in this example:

          def clean_and_verify_options!(map) do
            Map.delete(map, :debug)

            if Enum.length(map) == 0, do: raise "OMG!!!1"

            map
          end

      Map operations never work on the variable you pass in, but return a new
      variable which has to be used somehow.
      """
    ]

  alias Credo.Check.Warning.UnusedOperation

  @checked_module :Map
  @funs_with_return_value [
    :delete,
    :drop,
    :equal?,
    :fetch,
    :fetch!,
    :filter,
    :from_keys,
    :from_struct,
    :get,
    :get_and_update,
    :get_and_update!,
    :get_lazy,
    :has_key?,
    :intersect,
    :keys,
    :merge,
    :new,
    :pop,
    :pop!,
    :pop_lazy,
    :put,
    :put_new,
    :put_new_lazy,
    :reject,
    :replace,
    :replace!,
    :replace_lazy,
    :split,
    :split_with,
    :take,
    :to_list,
    :update,
    :update!,
    :values
  ]

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
