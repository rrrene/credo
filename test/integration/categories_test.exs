defmodule Credo.CategoriesTest do
  use Credo.Test.Case

  alias Credo.Test.IntegrationTest

  @moduletag slow: :integration

  test "it should NOT report issues on categories" do
    exec = IntegrationTest.run(["categories"])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "categories"
    assert issues == []
  end

  test "it should NOT report issues on categories (using --format json)" do
    exec = IntegrationTest.run(["categories", "--format", "json"])
    issues = Credo.Execution.get_issues(exec)

    assert exec.cli_options.command == "categories"
    assert issues == []
  end
end
