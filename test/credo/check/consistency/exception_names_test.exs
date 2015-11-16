defmodule Credo.Check.Consistency.ExceptionNamesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.ExceptionNames

  test "it should NOT report correct behaviour (same suffix)" do
    [
"""
defmodule Credo.Sample do
  defmodule UriParserError do
    defexception [:message]
  end
end
""",
"""
defmodule SomeOtherError do
  defexception [:message]
end
"""
    ]
    |> Enum.map(&to_source_file/1)
    |> refute_issues(@described_check)
  end

  test "it should NOT report correct behaviour (same prefix)" do
    [
"""
defmodule Credo.Sample do
  defmodule InvalidSomething do
    defexception [:message]
  end
end
""",
"""
defmodule InvalidResponse do
  defexception [:message]
end
"""
    ]
    |> Enum.map(&to_source_file/1)
    |> refute_issues(@described_check)
  end



  test "it should report a violation for different naming schemes" do
    [
"""
defmodule Credo.Sample do
  defmodule SomeError do
    defexception [:message]
  end
end
""",
"""
defmodule UndefinedResponse do
  defexception [:message]
end
"""
    ]
    |> Enum.map(&to_source_file/1)
    |> assert_issue(@described_check)
  end


  test "it should report a violation for different naming schemes (suffixes)" do
    [
"""
defmodule Credo.Sample do
  defmodule SomeException do
    defexception [:message]
  end
  defmodule UndefinedResponse do    # <--- does not have the suffix "Exception"
    defexception [:message]
  end
end
""",
"""
defmodule InputValidationException do
  defexception [:message]
end
"""
    ]
    |> Enum.map(&to_source_file/1)
    |> assert_issue(@described_check)
  end

  test "it should report a violation for different naming schemes (prefixes)" do
    [
"""
defmodule Credo.Sample do
  defmodule InvalidDataRequest do
    defexception [:message]
  end
end
""",
"""
defmodule InvalidReponseFromServer do
  defexception [:message]
end
""",
"""
defmodule UndefinedDataFormat do    # <--- does not have the prefix "Invalid"
  defexception [:message]
end
"""
    ]
    |> Enum.map(&to_source_file/1)
    |> assert_issue(@described_check)
  end

  test "it should not report (prefixes)" do
    [
"""
  defmodule FactoryUndefined do
    defexception [:message]

    def exception(factory_name) do
      message = "No factory defined for this."
      %UndefinedFactory{message: message}
    end
  end

  defmodule SaveUndefined do
    defexception [:message]
  end
"""
    ]
    |> Enum.map(&to_source_file/1)
    |> refute_issues(@described_check)
  end

end
