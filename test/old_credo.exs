# Mix.install([{:credo, "~> 1.7"}])
Mix.install([{:credo, github: "rrrene/credo", ref: "v1.7.12"}])

Credo.run(~w"--mute-exit-status --strict --enable-disabled-checks .+ --no-color --format oneline")
