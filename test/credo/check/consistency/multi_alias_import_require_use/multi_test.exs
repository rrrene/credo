defmodule Credo.Check.Consistency.MultiAliasImportRequireUse.MultiTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.MultiAliasImportRequireUse.Multi

  @multi """
defmodule Credo.Sample1 do
  alias Foo.{Bar, Baz}
  import Foo.{Bar, Baz}
  require Foo.{Bar, Baz}
  use Foo.{Bar, Baz}
end
"""

  @no_multi """
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

  @tag needs_elixir: "1.2.0"
  test "it should report the correct property value when the pattern is matched" do
    result =
      @multi
      |> to_source_file()
      |> Multi.property_value_for([])       
    assert 4 == Enum.count(result)
  end

  @tag needs_elixir: "1.2.0"
  test "it should not report anything when the pattern is not matched" do
    result =
      @no_multi
      |> to_source_file()
      |> Multi.property_value_for([])       
    assert result == []
  end

end
