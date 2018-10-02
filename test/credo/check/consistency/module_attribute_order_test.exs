defmodule Credo.Check.Consistency.ModuleAttributeOrderTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.ModuleAttributeOrder

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      @moduledoc ""

      @behaviour Example.Behaviour

      use Example

      import Example.Another

      alias Example.Alias

      require Example.Require

      defstruct [:one, :two, :three]

      @type t :: String.t()

      @my_attribute "attribute"

      @my_other_attribute "another"

      @callback example_cb() :: [String.t]

      @macrocallback my_macro(arg :: any) :: Macro.t

      @optional_callbacks optional_cb() :: [String.t]
    end
    """
    |> to_source_file()
    |> refute_issues(@described_check)
  end

  test "it should report a single violation" do
    """
    defmodule CredoSampleModule do
      @moduledoc ""

      use Example

      @behaviour Example.Behaviour

      import Example.Another
    end
    """
    |> to_source_file()
    |> assert_issue(@described_check)
  end

  test "it should report multiple violations" do
    """
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
    |> to_source_file()
    |> assert_issues(@described_check)
  end

  test "it should ensure each grouping of attributes or directives is alphabetized" do
    """
    defmodule CredoSampleModule do
      @moduledoc ""

      @behaviour Example.Behaviour
      @behaviour AnotherExample.Behaviour
    end
    """
    |> to_source_file()
    |> assert_issue(@described_check)
  end
end
