# Used by "mix format" and to export configuration.
export_locals_without_parens = [
  run: 1,
  run: 2,
  activity: 1,
  activity: 2
]

[
  inputs: ["{mix,.formatter,.credo}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: export_locals_without_parens,
  export: [locals_without_parens: export_locals_without_parens]
]
