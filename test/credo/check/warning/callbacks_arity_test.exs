defmodule Credo.Check.Warning.CallbacksArityTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.CallbacksArity

  test "it should report expected code" do
"""
defmodule WithWarnings do
  use GenServer

  def handle_call(:x, state) do
    # Notice the missing "from" parameter
    {:reply, :y, state}
  end
end
""" |> to_source_file
    |> ensure_loaded_source_file
    |> assert_issue(@described_check)
  end

  test "it should report expected code (custom behaviour)" do
"""
defmodule WithWarnings2 do
  @behaviour TestBehaviour

  # this is fine
  def parse(str) when is_binary(str), do: str

  # this will emit an issue
  def parse(str, str2), do: {str, str2}
end
""" |> to_source_file
    |> ensure_loaded_source_file
    |> assert_issue(@described_check)
  end

  test "it should report expected code (OTP behaviour with custom behaviour)" do
"""
defmodule WithWarnings3 do
  use GenServer
  @behaviour TestBehaviour

  # this is fine
  def parse(str) when is_binary(str), do: str 

  # this will emit an issue
  def parse(str, str2), do: {str, str2} 

  # this will emit an issue
  def handle_call(:x, state) do
    # Notice the missing "from" parameter
    {:reply, :y, state}
  end
end
""" |> to_source_file
    |> ensure_loaded_source_file
    |> assert_issues(@described_check)
  end

  test "it should report expected code (custom callback with guard clause)" do
"""
defmodule WithWarnings4 do
  @behaviour TestBehaviour

  def parse(str) when is_binary(str), do: str
  def parse(str, str2) when is_binary(str), do: {str, str2}
end
""" |> to_source_file
    |> ensure_loaded_source_file
    |> assert_issue(@described_check)
  end

  test "it should NOT report expected code" do
"""
defmodule WithoutWarnings do
  use GenServer

  def handle_call(:x, from, state) do
    # Notice the missing "from" parameter
    {:reply, from, state}
  end
end
""" |> to_source_file
    |> ensure_loaded_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report expected code (behaviour requirements are fulfilled)" do
"""
defmodule WithoutWarnings2 do
  @behaviour TestBehaviour

  def parse(str), do: str
end
""" |> to_source_file
    |> ensure_loaded_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report expected code (empty not evaluated module)" do
"""
defmodule WithoutWarnings3 do
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report expected code (empty evaluated module)" do
"""
defmodule WithoutWarnings4 do
end
""" |> to_source_file
    |> ensure_loaded_source_file
    |> refute_issues(@described_check)
  end
end
