# Testing Custom Checks

`Credo.Test.Case` provides conveniences for testing Credo custom checks and plugins.

This module can be used in your test cases, like this:

    use Credo.Test.Case

Using this module will:

* import all the functions from this module
* make the test case `:async` by default (use `async: false` to opt out of this behaviour)

Let's test the `RejectModuleAttributes` check that we implemented in [Adding custom checks](adding_checks.html).

### Basic custom check tests

To test a check, we can use `Credo.Test.Case` for convenience:

    defmodule MyProject.Checks.RejectModuleAttributesTest do
      use Credo.Test.Case

      alias MyProject.Checks.RejectModuleAttributes

      test "it should NOT report expected code" do
        """
        defmodule CredoSampleModule do
          @somedoc "This is somedoc"
        end
        """
        |> to_source_file()
        |> run_check(RejectModuleAttributes)
        |> refute_issues()
      end

      test "it should report code that includes rejected module attribute names" do
        """
        defmodule CredoSampleModule do
          @checkdoc "This is checkdoc"
        end
        """
        |> to_source_file()
        |> run_check(RejectModuleAttributes)
        |> assert_issues()
      end
    end

We have two tests: one for the good case, one for the bad case.
In each, we create a source file representation from a heredoc, run our custom check and assert/refute the issues
we expect.

### Using custom params in tests

We can (and should) also test the params of our check by passing them to `run_check/2`:

    defmodule MyProject.Checks.RejectModuleAttributesTest do
      use Credo.Test.Case

      alias MyProject.Checks.RejectModuleAttributes
      
      # ...

      test "it should NOT report code that includes default rejected module attribute names when a custom set of rejected names is provided" do
        """
        defmodule CredoSampleModule do
          @checkdoc "This is checkdoc"
        end
        """
        |> to_source_file()
        |> run_check(RejectModuleAttributes, reject: [:somedoc])
        |> refute_issues()
      end

      test "it should report expected code when a custom set of rejected names is provided" do
        """
        defmodule CredoSampleModule do
          @somedoc "This is somedoc"
        end
        """
        |> to_source_file()
        |> run_check(RejectModuleAttributes, reject: [:somedoc])
        |> assert_issues()
      end
    end

### Asserting found issues

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
    |> run_check(RejectModuleAttributes)
    |> assert_issue(fn issue -> assert issue.trigger == "@checkdoc" end)

... or properties of the list of issues:

    """
    # ... any Elixir code ...
    """
    |> to_source_file()
    |> run_check(RejectModuleAttributes)
    |> assert_issue(fn issues -> assert Enum.count(issues) == 3 end)

### Testing checks that analyse multiple source files

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
    |> run_check(RejectModuleAttributes)
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
    |> run_check(RejectModuleAttributes)
    |> assert_issue(fn issue -> assert issue.filename == "foo.ex" end)
