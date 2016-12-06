defmodule Credo.Check.Readability.PreferImplicitTryTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.PreferImplicitTry

  test "it should NOT report expected code" do
"""
defmodule ModuleWithImplicitTry do
  def failing_function(first) do
    to_string(first)
  rescue
    _ -> :rescued
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report a violation" do
"""
defmodule ModuleWithExplicitTry do
   def failing_function(first) do
     try do
       to_string(first)
      rescue
        _ -> :rescued
     end
   end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation where try isn't first" do
"""
defmodule ModuleWithExplicitTry do
   def failing_function(first) do
     a = to_atom(first)

     try do
       to_string(first)
      rescue
        _ -> :rescued
     end

     [a, first]
   end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should NOT report a violation in cases where we need `try`" do
"""
defmodule ModuleWithExplicitTry do
   def failing_function(first) do
     other_function()

     str = try do
       to_string(first)
      rescue
        _ -> "rescued" 
     end

     to_atom(string)
   end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

end
