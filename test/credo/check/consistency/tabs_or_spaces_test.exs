defmodule Credo.Check.Consistency.TabsOrSpacesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.TabsOrSpaces

  @with_tabs """
defmodule Credo.Sample do
\t@test_attribute :foo

\tdef foobar(parameter1, parameter2) do
\t\tString.split(parameter1) + parameter2
\tend
end
"""
  @with_spaces """
defmodule Credo.Sample do
  defmodule InlineModule do
    def foobar do
      {:ok} = File.read
    end
  end
end
"""
  @with_spaces2 """
defmodule OtherModule do
  defmacro foo do
    {:ok} = File.read
  end

  defp bar do
    :ok
  end
end
"""

  test "it should report the correct scope" do
    [
      @with_tabs, @with_spaces, @with_spaces2
    ]
    |> Enum.map(&to_source_file/1)
    |> assert_issues(@described_check)
  end

end
