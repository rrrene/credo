# Testing Custom Checks

`Credo.Test.Case` provides conveniences for testing Credo custom checks and plugins.

This module can be used in your test cases, like this:

    use Credo.Test.Case

Using this module will:

* import all the functions from this module
* make the test case `:async` by default (use `use Credo.Test.Case, async: false` to opt out)

Suppose we have a custom check in our project that checks whether or not
the "FooBar rules" are applied (one of those *very* project-specific things).

    defmodule MyProject.MyCustomChecks.FooBar do
      use Credo.Check, category: :warning, base_priority: :high

      def run(source_file, params) do
        # ... implement all the "FooBar rules" ...
      end
    end

When we want to test this check, we can use `Credo.Test.Case` for convenience:

    defmodule MyProject.MyCustomChecks.FooBarTest do
      use Credo.Test.Case

      alias MyProject.MyCustomChecks.FooBar

      test "it should NOT report expected code" do
        """
        defmodule CredoSampleModule do
          # ... some good Elixir code ...
        end
        """
        |> to_source_file()
        |> run_check(FooBar)
        |> refute_issues()
      end

      test "it should report code that violates the FooBar rule" do
        """
        defmodule CredoSampleModule do
          # ... some Elixir code that violates the FooBar rule ...
        end
        """
        |> to_source_file()
        |> run_check(FooBar)
        |> assert_issues()
      end
    end

This is as simple and mundane as it looks (which is a good thing):
We have two tests: one for the good case, one for the bad case.
In each, we create a source file representation from a heredoc, run our custom check and assert/refute the issues
we expect.

## Asserting found issues

Once we get to know domain a little better, we can add more tests, typically testing for other bad cases in which
our check should produce issues.

Note that there are two assertion functions for this: `assert_issue/2` and `assert_issues/2`, where the first one
ensures that there is a single issue and the second asserts that there are at least two issues.

Both functions take an optional `callback` as their second parameter, which is called with the `issue` or the
list of `issues` found, which makes it convenient  to check for the issues properties ...

    """
    # ... any Elixir code ...
    """
    |> to_source_file()
    |> run_check(FooBar)
    |> assert_issue(fn issue -> assert issue.trigger == "foo" end)

... or properties of the list of issues:

    """
    # ... any Elixir code ...
    """
    |> to_source_file()
    |> run_check(FooBar)
    |> assert_issue(fn issues -> assert Enum.count(issues) == 3 end)

## Testing checks that analyse multiple source files

For checks that analyse multiple source files, like Credo's consistency checks, we can use `to_source_files/1` to
create

    [
      """
      # source file 1
      """,
      """
      # source file 2
      """
    ]
    |> to_source_files()
    |> run_check(FooBar)
    |> refute_issues()

If our check needs named source files, we can always use `to_source_file/2` to create individually named source
files and combine them into a list:

    source_file1 =
      """
      # source file 1
      """
      |> to_source_file("foo.ex")

    source_file2 =
      """
      # source file 2
      """
      |> to_source_file("bar.ex")

    [source_file1, source_file2]
    |> run_check(FooBar)
    |> assert_issue(fn issue -> assert issue.filename == "foo.ex" end)
