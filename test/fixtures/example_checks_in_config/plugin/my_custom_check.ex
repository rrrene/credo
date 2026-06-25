
defmodule ExampleCheckPlugin.MyCustomCheck do
  # Set up the behaviour and make this module a "check":
  use Credo.Check

  # The minimum each check has to implement is a `run/2` function which returns the found issues:
  def run(source_file, params \\ []) do
    []
  end
end