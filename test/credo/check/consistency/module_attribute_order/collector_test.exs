defmodule Credo.Check.Consistency.ModuleAttributeOrder.CollectorTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.ModuleAttributeOrder.Collector

  @unordered """
  defmodule CredoSampleModule do
    @optional_callbacks optional_cb() :: [String.t]

    @my_attribute "attribute"

    @type t :: String.t()

    alias Example.Alias

    require Example.Require

    import Example.Another

    use Example
  end
  """

  test "it should report line number of unordered attributes" do
    result =
      @unordered
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{ordered: 1, unordered: 5} == result
  end
end
