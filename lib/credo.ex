defmodule Credo do
  @moduledoc """
  Credo builds upon four building blocks:

  - `Credo.CLI` - everything related to the command line interface (CLI), which orchestrates the analysis
  - `Credo.Execution` - a struct which is handed down the pipeline during analysis
  - `Credo.Check` - the default Credo checks
  - `Credo.Code` - all analysis tools used by Credo during analysis
  """

  @version Mix.Project.config()[:version]

  def version, do: @version
end
