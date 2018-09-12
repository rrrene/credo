defmodule Credo.Server do
  alias Credo.Execution
  alias Credo.MainProcess

  def run(project_dir, argv, %{} = _) do
    Credo.Application.start(nil, nil)

    %Execution{argv: [project_dir | argv]}
    |> MainProcess.call()
    |> Execution.get_issues()
  end
end
