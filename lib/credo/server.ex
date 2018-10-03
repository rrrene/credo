defmodule Credo.Server do
  @moduledoc """
  Credo Server

      argv = ["--strict"]
      token = Credo.Server.build("/home/rene/projects/html_sanitize_ex", argv)

      # run Credo on the project again
      Credo.Server.run(token)

      # run Credo on a specific file
      Credo.Server.run_file(token, "lib/my_app/my_file.ex")

      # run Credo on a specific file
      Credo.Server.run_file(token, "lib/my_app/my_file.ex", content \\ nil)
  """

  defmodule Session do
    defstruct [:project_dir, :argv]
  end

  alias __MODULE__.Session
  alias Credo.Execution
  alias Credo.MainProcess

  def build(project_dir, argv) when is_binary(project_dir) and is_list(argv) do
    %Session{project_dir: project_dir, argv: argv}
  end

  def clean_run(project_dir, argv, %{} = _source_files) do
    Credo.Application.start(nil, nil)

    %Execution{argv: [project_dir | argv]}
    |> MainProcess.call()
    |> Execution.get_issues()
  end

  def run_files(%Session{} = token, %{} = source_files) do
    clean_run(token.project_dir, token.argv, source_files)
  end
end
