defmodule Credo.Check.Consistency.MultiImport.CollectorTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.MultiImport.Collector

  @single """
  defmodule Credo.Sample1 do
    alias Foo.Bar
    import Foo.Bar
    import Foo.Baz # this and the first line counts as 1
    import Bar.Foo
    import Bar.Baz # this and the first line counts as 1
    import Bar # use with single module alias does not count
    require Foo.Bar
    use Foo.Bar
  end
  """

  @multi """
  defmodule Credo.Sample2 do
    import Foo.{Bar, Baz}
    import Foo
    import Bar.Baz
    alias Foo.Bar
    require Foo.Bar
    use Foo.Bar
  end
  """

  @mixed """
  defmodule Credo.Sample2 do
    import Foo.{Bar, Baz}
    import Foo.Quux
    alias Foo.Baz
    require Foo.Bar
    use Foo.Bar
  end
  """

  test "it should report correct frequencies for single imports" do
    result =
      @single
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{single: 2} == result
  end

  test "it should report correct frequencies for multi imports" do
    result =
      @multi
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{multi: 1} == result
  end

  test "it should report correct frequencies for mixed imports" do
    result =
      @mixed
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{single: 1, multi: 1} == result
  end
end
