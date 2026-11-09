%{
  configs: [
    %{
      name: "default",
      files: %{included: ["lib/"]},
      checks: %{
        enabled: [
          {Credo.Check.Readability.ModuleDoc, files: %{excluded: ["lib/excluded.ex"]}}
        ]
      }
    }
  ]
}
