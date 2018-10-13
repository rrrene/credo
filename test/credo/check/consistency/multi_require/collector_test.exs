defmodule Credo.Check.Consistency.MultiRequire.CollectorTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.MultiRequire.Collector

  @single """
  defmodule Credo.Sample1 do
    alias Foo.Bar
    require Foo.Bar
    require Foo.Baz # this and the first line counts as 1
    require Bar.Foo
    require Bar.Baz # this and the first line counts as 1
    require Bar # use with single module alias does not count
    import Foo.Bar
    use Foo.Bar
  end
  """

  @multi """
  defmodule Credo.Sample2 do
    require Foo.{Bar, Baz}
    require Foo
    require Bar.Baz
    alias Foo.Bar
    import Foo.Bar
    use Foo.Bar
  end
  """

  @mixed """
  defmodule Credo.Sample2 do
    require Foo.{Bar, Baz}
    require Foo.Quux
    alias Foo.Baz
    import Foo.Bar
    use Foo.Bar
  end
  """

  test "it should report correct frequencies for single requires" do
    result =
      @single
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{single: 2} == result
  end

  test "it should report correct frequencies for multi requires" do
    result =
      @multi
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{multi: 1} == result
  end

  test "it should report correct frequencies for mixed requires" do
    result =
      @mixed
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{single: 1, multi: 1} == result
  end
end
