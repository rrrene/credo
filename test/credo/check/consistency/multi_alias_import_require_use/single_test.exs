defmodule Credo.Check.Consistency.MultiAliasImportRequireUse.SingleTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.MultiAliasImportRequireUse.Single

  @single """
defmodule Credo.Sample2 do
  alias Foo.Bar
  alias Foo.Baz
  import Foo.Bar
  import Foo.Baz  
  require Foo.Bar
  require Foo.Baz
  use Foo.Bar
  use Foo.Baz  
end
"""

  @no_single """
defmodule Credo.Sample1 do
  alias Foo.{Bar, Baz}
  import Foo.{Bar, Baz}
  require Foo.{Bar, Baz}
  use Foo.{Bar, Baz}
end
"""

  test "it should report the correct property value when the pattern is matched" do
    result =
      @single
      |> to_source_file()
      |> Single.property_value_for([])       
      assert 4 == Enum.count(result)
  end

  test "it should not report anything when the pattern is not matched" do
    result =
      @no_single
      |> to_source_file()
      |> Single.property_value_for([])       
      assert result == []
  end

end