{%{
   configs: [
     %{checks: checks}
   ]
 }, _} = Code.eval_file(".credo.exs")

all_checks =
  Enum.map(checks.disabled ++ checks.enabled, fn {check_mod, _params} ->
    {check_mod.id(), check_mod}
  end)
  |> Enum.sort()
  |> Enum.map(&elem(&1, 1))

# Enum.map(all_checks, fn check ->
#   params = Keyword.keys(List.wrap(check.explanations[:params]))

#   if params != [] do
#     {check, params}
#   end
# end)
# |> Enum.reject(&is_nil/1)
# |> Enum.each(fn {check, params} ->
#   check_name = to_string(check) |> String.replace(~r/^Elixir\./, "")
#   IO.puts("#{String.pad_trailing(check_name, 54)}  #{inspect(params)}")
# end)

Enum.map(all_checks, fn check ->
  params = Keyword.keys(List.wrap(check.explanations()[:params]))

  {String.replace(to_string(check), "Elixir.Credo.Check.", "."), check.id(), params}
end)
|> Enum.reject(&is_nil/1)
|> Enum.each(fn {check, id, params} ->
  IO.puts("#{String.pad_trailing(check, 44)} #{inspect(id)}  #{inspect(params)}")
end)
