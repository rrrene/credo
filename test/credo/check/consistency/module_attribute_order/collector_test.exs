defmodule Credo.Check.Consistency.ModuleAttributeOrder.CollectorTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.ModuleAttributeOrder.Collector

  @all_relevant_attributes """
  defmodule Credo.Sample1 do
    @moduledoc false

    @behaviour SomeBehaviour

    use SomeModule

    import AnotherModule

    alias AThirdModule
    alias YetAnotherModule

    require Logger

    defstruct [:some, :fields]

    @some_attribute :with_some_value

    @type my_type :: any()
    @type another_type :: any()

    @callback a_callback() :: any()

    @macrocallback a_macro_callback(keyword()) :: no_return

    @optional_callbacks a_callback: 0

    @impl true
    def some_function, do: :ok
  end
  """

  @some_attributes """
  defmodule Credo.Sample2 do
    @moduledoc false

    use SomeModule

    alias AThirdModule
    alias YetAnotherModule

    require Logger

    @some_attribute :with_some_value

    @type my_type :: any()
    @type another_type :: any()

    @impl true
    def some_function, do: :ok
  end
  """

  @interspersed_attributes """
  defmodule Credo.Sample2 do
    @moduledoc false

    use SomeModule

    import AnotherModule

    require Logger

    @some_attribute :with_some_value

    alias YetAnother.GreatModule

    require Stuff

    @type my_type :: any()
    @type another_type :: any()

    alias MyNested.Awesomeness

    @impl true
    def some_function, do: :ok
  end
  """

  @multi_module_attributes """
  defmodule Credo.Sample2 do
    @moduledoc false

    use SomeModule

    alias AThirdModule
    alias YetAnotherModule

    require Logger

    @some_attribute :with_some_value

    @type my_type :: any()
    @type another_type :: any()

    defmodule Nested do
      @moduledoc false

      use OtherModule

      alias Stuff
      alias MoreStuff

      def my_function, do: :ok
    end
  end
  """

  describe ".collect_matches/2" do
    test "it should report all relevant attributes in the used order" do
      result =
        @all_relevant_attributes
        |> to_source_file()
        |> Collector.collect_matches([])

      assert result == %{
               [
                 :moduledoc,
                 :behaviour,
                 :use,
                 :import,
                 :alias,
                 :require,
                 :defstruct,
                 :moduleattribute,
                 :type,
                 :callback,
                 :macrocallback,
                 :optional_callbacks
               ] => 1
             }
    end

    test "it should report the relevant used attributes but not all in the used order" do
      result =
        @some_attributes
        |> to_source_file()
        |> Collector.collect_matches([])

      assert result == %{
               [
                 :moduledoc,
                 :use,
                 :alias,
                 :require,
                 :moduleattribute,
                 :type
               ] => 1
             }
    end

    test "it should report the relevant used attributes in the order they first appeared" do
      result =
        @interspersed_attributes
        |> to_source_file()
        |> Collector.collect_matches([])

      assert result == %{
               [
                 :moduledoc,
                 :use,
                 :import,
                 :require,
                 :moduleattribute,
                 :alias,
                 :type
               ] => 1
             }
    end

    test "it should report the used attributes per module and respect nested modules" do
      result =
        @multi_module_attributes
        |> to_source_file()
        |> Collector.collect_matches([])

      assert result == %{
               [
                 :moduledoc,
                 :use,
                 :alias,
                 :require,
                 :moduleattribute,
                 :type
               ] => 1,
               [
                 :moduledoc,
                 :use,
                 :alias
               ] => 1
             }
    end
  end

  describe ".transform_frequencies/1" do
    test "it should merge frequencies for matches where some attributes are simply unused" do
      frequencies = %{
        [
          :moduledoc,
          :use,
          :alias,
          :type
        ] => 23,
        [
          :use,
          :alias,
          :require,
          :type
        ] => 20,
        [
          :moduledoc,
          :require,
          :alias
        ] => 1
      }

      assert Collector.transform_frequencies(frequencies) == %{
               [
                 :moduledoc,
                 :use,
                 :alias,
                 :require,
                 :type
               ] => 23 + 20,
               [
                 :moduledoc,
                 :require,
                 :alias
               ] => 1
             }
    end

    test "it should merge frequencies for matches where the order is unclear by looking at the rest" do
      frequencies = %{
        [
          :moduledoc,
          :use,
          :alias,
          :type
        ] => 23,
        [
          :use,
          :alias,
          :require
        ] => 20,
        [
          :alias,
          :require,
          :type,
          :callback
        ] => 10,
        [
          :moduledoc,
          :require,
          :alias
        ] => 1
      }

      assert Collector.transform_frequencies(frequencies) == %{
               [
                 :moduledoc,
                 :use,
                 :alias,
                 :require,
                 :type,
                 :callback
               ] => 23 + 20 + 10,
               [
                 :moduledoc,
                 :require,
                 :alias
               ] => 1
             }
    end
  end
end
