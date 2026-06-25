%{
  configs: [
    %{
      name: "default",
      checks: %{
        extra: [
          {Something.That.Is.Probably.Not.Loaded, false},
          {ExampleCheckPlugin.MyCustomCheck, []}
        ]
      }
    }
  ]
}
