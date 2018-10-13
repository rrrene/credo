defmodule Credo.Check.Consistency.MultiAlias.CollectorTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.MultiAlias.Collector

  @single """
  defmodule Credo.Sample1 do
    alias Foo.Bar
    import Foo.Bar
    alias Foo.Baz # this and the first line counts as 1
    alias Bar.Foo
    alias Bar.Baz # this and the first line counts as 1
    alias Bar # use with single module alias does not count
    require Foo.Bar
    use Foo.Bar
  end
  """

  @multi """
  defmodule Credo.Sample2 do
    alias Foo.{Bar, Baz}
    alias Foo
    alias Bar.Baz
    import Foo.Bar
    require Foo.Bar
    use Foo.Bar
  end
  """

  @mixed """
  defmodule Credo.Sample2 do
    alias Foo.{Bar, Baz}
    alias Foo.Quux
    import Foo.Baz
    require Foo.Bar
    use Foo.Bar
  end
  """

  test "it should report correct frequencies for single aliases" do
    result =
      @single
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{single: 2} == result
  end

  test "it should report correct frequencies for multi aliases" do
    result =
      @multi
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{multi: 1} == result
  end

  test "it should report correct frequencies for mixed aliases" do
    result =
      @mixed
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{single: 1, multi: 1} == result
  end
end
