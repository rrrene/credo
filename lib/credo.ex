defmodule Credo do
  use Application

  @version Mix.Project.config[:version]

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children =
      [
        worker(Credo.CLI.Output.Shell, []),
        worker(Credo.Service.Commands, []),
        worker(Credo.Service.SourceFileScopes, []),
        worker(Credo.Service.SourceFileAST, []),
        worker(Credo.Service.SourceFileLines, []),
        worker(Credo.Service.SourceFileSource, []),
      ]

    opts = [strategy: :one_for_one, name: Credo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def version, do: @version
end
