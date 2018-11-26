defmodule Credo.Check.Consistency.ModuleAttributeOrderTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.ModuleAttributeOrder

  @not_alphabetized """
  defmodule CredoSampleModule do
    @moduledoc ""

    @behaviour Example.Behaviour
    @behaviour AnotherExample.Behaviour
  end
  """

  @not_ordered """
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

  @ordered """
  defmodule CredoSampleModule do
    @moduledoc ""

    @behaviour Example.Behaviour

    import Example.Another

    alias Example.Alias

    @optional_callbacks optional_cb() :: [String.t]
  end
  """

  test "it should not report consistent ordering" do
    [@ordered]
    |> to_source_files
    |> refute_issues(@described_check)
  end

  test "it should report inconsistently ordered module attributes" do
    [@ordered, @not_ordered]
    |> to_source_files
    |> assert_issues(@described_check)
  end

  test "it should ensure each grouping of attributes or directives is alphabetized" do
    [@ordered, @not_alphabetized]
    |> to_source_files
    |> assert_issues(@described_check)
  end
end
