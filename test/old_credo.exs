Mix.install([{:credo, "~> 1.7"}])

Credo.run(~w"--mute-exit-status --strict --enable-disabled-checks .+ --no-color --format oneline")
