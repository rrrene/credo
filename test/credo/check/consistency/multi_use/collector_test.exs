defmodule Credo.Check.Consistency.MultiUse.CollectorTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.MultiUse.Collector

  @single """
  defmodule Credo.Sample1 do
    alias Foo.Bar
    use Foo.Bar
    use Foo.Baz # this and the first line counts as 1
    use Bar.Foo
    use Bar.Baz # this and the first line counts as 1
    use Bar # use with single module alias does not count
    import Foo.Bar
    require Foo.Bar
  end
  """

  @multi """
  defmodule Credo.Sample2 do
    use Foo.{Bar, Baz}
    use Foo
    use Bar.Baz
    alias Foo.Bar
    import Foo.Bar
    require Foo.Bar
  end
  """

  @mixed """
  defmodule Credo.Sample2 do
    use Foo.{Bar, Baz}
    use Foo.Quux
    alias Foo.Baz
    import Foo.Bar
    require Foo.Bar
  end
  """

  test "it should report correct frequencies for single uses" do
    result =
      @single
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{single: 2} == result
  end

  test "it should report correct frequencies for multi uses" do
    result =
      @multi
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{multi: 1} == result
  end

  test "it should report correct frequencies for mixed uses" do
    result =
      @mixed
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{single: 1, multi: 1} == result
  end
end
