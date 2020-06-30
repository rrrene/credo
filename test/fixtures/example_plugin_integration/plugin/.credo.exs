%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Readability.LargeNumbers, false}
      ]
    }
  ]
}
