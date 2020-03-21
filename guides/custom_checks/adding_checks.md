# Adding Custom Checks

There comes a time when Credo does not feature the check you need or where you want to test a project- or domain-specific aspect of your codebase.

This is when you should consider implementing a Custom Check.

Custom checks are simply modules implementing the `Credo.Check` behaviour, which most of the time means that it is a module with a `run/2` function returning a list of `Credo.Issue` structs:

    # lib/checks/my_check.ex
    defmodule MyProject.Checks.MyCheck do
      use Credo.Check

      def run(source_file, params) do
        #
      end
    end

Check `Credo.Check` for more information.


## Configuring Custom Checks with parameters

The `params` keyword list can be set in [`.credo.exs`](config_file.html):

    {MyProject.Checks.MyCheck, [disallow: [:shortdoc]]}

