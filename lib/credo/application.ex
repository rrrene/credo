defmodule Credo.Application do
  @moduledoc false

  use Application

  @worker_modules [
    Credo.CLI.Output.Shell,
    Credo.Service.SourceFileAST,
    Credo.Service.SourceFileLines,
    Credo.Service.SourceFileScopes,
    Credo.Service.SourceFileSource
  ]

  if Version.match?(System.version(), ">= 1.10.0-rc") do
    def children() do
      Enum.map(@worker_modules, &{&1, []})
    end
  else
    def children() do
      import Supervisor.Spec, warn: false
      Enum.map(@worker_modules, &worker(&1, []))
    end
  end

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Credo.Supervisor]
    Supervisor.start_link(children(), opts)
  end
end
