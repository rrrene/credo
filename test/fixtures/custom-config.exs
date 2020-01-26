%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "web/", "apps/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Readability.ModuleDoc, false}
      ]
    },
    %{
      name: "empty-config"
    }
  ]
}
