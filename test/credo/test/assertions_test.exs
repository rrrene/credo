defmodule Credo.Test.AssertionsTest do
  use ExUnit.Case, async: true

  import Credo.Test.Assertions

  alias Credo.Issue

  test "it should assert issues" do
    [%Issue{}]
    |> assert_issue()
  end

  test "it should not assert an empty list of issues" do
    assert_raise ExUnit.AssertionError, fn ->
      []
      |> assert_issue()
    end
  end

  test "it should assert a list of issues" do
    [%Issue{}, %Issue{}]
    |> assert_issues()
  end

  test "it should not assert a list of one issue as assert_issues/1" do
    assert_raise ExUnit.AssertionError, fn ->
      []
      |> assert_issues()
    end
  end

  test "it should refute issues" do
    []
    |> refute_issues()
  end

  test "it should not refute a list of issues" do
    assert_raise ExUnit.AssertionError, fn ->
      [%Issue{}]
      |> refute_issues()
    end
  end
end
