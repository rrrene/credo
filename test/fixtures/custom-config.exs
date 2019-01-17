%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "web/", "apps/"],
        excluded: []
      },
      requires: [
        "lib/custom_checks.ex"
      ],
      checks: [
        {Credo.Check.Readability.ModuleDoc, false}
      ]
    }
  ]
}
