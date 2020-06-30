defmodule Credo.Check.Consistency.MultiAliasImportRequireUse.CollectorTest do
  use Credo.Test.Case

  alias Credo.Check.Consistency.MultiAliasImportRequireUse.Collector

  @single """
  defmodule Credo.Sample1 do
    alias Foo.Bar
    import Foo.Bar
    alias Foo.Baz # this and the first line counts as 1
    import Foo.Baz # this and the second line counts as 1
    require Foo.Bar
    require Foo.Baz # this and the previous line counts as 1
    use Foo.Bar
    use Foo.Baz, with_params: true # use with params does not count
    use Foo # use with single module alias does not count
  end
  """

  @multi """
  defmodule Credo.Sample2 do
    alias Foo.{Bar, Baz}
    import Foo.{Bar, Baz}
    require Foo.{Bar, Baz}
    use Foo.{Bar, Baz}
  end
  """

  @mixed """
  defmodule Credo.Sample2 do
    import Foo.Bar
    alias Foo.{Bar, Baz}
    import Foo.Baz
    import Bar.Baz
  end
  """

  test "it should report correct frequencies for single imports" do
    result =
      @single
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{single: 3} == result
  end

  test "it should report correct frequencies for multi imports" do
    result =
      @multi
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{multi: 4} == result
  end

  test "it should report correct frequencies for mixed imports" do
    result =
      @mixed
      |> to_source_file()
      |> Collector.collect_matches([])

    assert %{single: 1, multi: 1} == result
  end
end
