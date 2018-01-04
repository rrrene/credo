# Used by "mix format" and to export configuration.
export_locals_without_parens = [
  task: 1,
  task: 2,
  group: 1,
  group: 2,
]

[
  inputs: ["{mix,.formatter,.credo}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: export_locals_without_parens,
  export: [locals_without_parens: export_locals_without_parens]
]
