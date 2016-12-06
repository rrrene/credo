defmodule Credo.CLI.Sorter do
  def ensure(list, list_start, list_end \\ []) do
    list
    |> to_start(list_start)
    |> to_end(list_end)
  end

  def to_start(list, list_start) do
    list_start = Enum.filter(list_start, &(Enum.member?(list, &1)))

    list_start ++ (list -- list_start)
  end

  def to_end(list, list_end) do
    list_end = Enum.filter(list_end, &(Enum.member?(list, &1)))

    (list -- list_end) ++ list_end
  end
end
