defmodule Credo.Test.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Credo.Test.FilenameGenerator, [])
    ]

    opts = [strategy: :one_for_one, name: Credo.Test.Application.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
