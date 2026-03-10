{argv, additional_credo_args} =
  case Enum.split_while(System.argv(), &(&1 != "--")) do
    {argv, []} -> {argv, []}
    {argv, ["--" | rest]} -> {argv, rest}
  end

old_credo_ref = List.first(argv) || "v1.7.17"

credo_opts =
  if old_credo_ref == "." do
    [path: "."]
  else
    [github: "rrrene/credo", ref: old_credo_ref]
  end

Mix.install([{:credo, credo_opts}, {:credo_tokenizer, ">= 0.0.0"}])

IO.puts(:stderr, "\n[version] credo #{Credo.version()} (installed from #{old_credo_ref})\n")

args =
  ~w"--mute-exit-status --strict --enable-disabled-checks .+ --no-color --format oneline" ++
    additional_credo_args

IO.puts(:stderr, "[run] $ mix credo #{Enum.join(args, " ")}\n")

Credo.run(args)
