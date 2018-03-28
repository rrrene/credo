defmodule Credo do
  @moduledoc """
  Credo is composed of these namespaces:

    * `Credo.Check` - checks are the building blocks of Credo's analysis. Each check analyses a part of the source code based on configurable parameters and returns found issues. A check can run on all files at once or on individual files.

    * `Credo.CLI` - CLI commands like `mix credo explain` are defined here.
    Additionally, this module holds everything else necessary to provide the command line interface experience, e.g. option parsing and output formatting.

    * `Credo.Code` - all of Credo's general purpose code analysing functions are stored here. These include utility functions for working with ASTs, tokens and text analysis.

    * `Credo.Execution` - modules responsible for orchestrating the flow of Credo's business logic. This includes metaprogramming facilities for the definition of business processes comprised of activities which are a series of tasks.

  """

  @version Mix.Project.config()[:version]

  @doc "Returns Credo's version"
  def version, do: @version
end
