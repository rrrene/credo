{argv, additional_credo_args} =
  case Enum.split_while(System.argv(), &(&1 != "--")) do
    {argv, []} -> {argv, []}
    {argv, ["--" | rest]} -> {argv, rest}
  end

old_credo_ref = List.first(argv) || "db3ec988e498dd8c706e4ebc4125860d610161c4"

if old_credo_ref == "." do
  Mix.install([{:credo, path: "."}])
else
  Mix.install([{:credo, github: "rrrene/credo", ref: old_credo_ref}])
end

IO.puts(:stderr, "\n[version] credo #{Credo.version()} (installed from #{old_credo_ref})\n")

args =
  ~w"--mute-exit-status --strict --enable-disabled-checks .+ --no-color --format oneline" ++
    additional_credo_args

IO.puts(:stderr, "[run] $ mix credo #{Enum.join(args, " ")}\n")

Credo.run(args)
