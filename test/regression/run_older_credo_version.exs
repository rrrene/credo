[credo_version | rest] = System.argv()

Mix.install([
  {:credo, credo_version}
])

Credo.run(rest)
