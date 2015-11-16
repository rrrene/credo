# This file contains the configuration for Credo.
# If you find anything wrong or unclear in this file, please report an
# issue on GitHub: https://github.com/rrrene/credo/issues
%{
  # You can have as many configs as you like under the "configs" key.
  configs: [
    %{
      #
      # names are arbitrary, default is "default"
      # run any config using the "-C" switch
      name: "default",
      #
      # these are the files included in the analysis
      files: %{
        #
        # you can give explicit globs or simply directories
        # in the latter case `**/*.{ex,exs}` will be used
        included: ["lib/", "src/", "web/"],
        excluded: []
      },
      #
      # all these checks are run
      # you can include configuration as the second element of the tuple
      #
      # there are two ways of deactivating a check:
      # 1. deleting the check from this list
      # 2. putting `false` as second element (to quickly "comment it out")
      #
      checks: [
        {Credo.Check.Consistency.ExceptionNames},
        {Credo.Check.Consistency.LineEndings},
        {Credo.Check.Consistency.TabsOrSpaces},

        {Credo.Check.Design.AliasUsage},
        {Credo.Check.Design.DuplicatedCode},
        {Credo.Check.Design.TagFIXME},
        {Credo.Check.Design.TagTODO},

        {Credo.Check.Readability.FunctionNames},
        {Credo.Check.Readability.MaxLineLength},
        {Credo.Check.Readability.ModuleAttributeNames},
        {Credo.Check.Readability.ModuleNames},
        {Credo.Check.Readability.PredicateFunctionNames},
        {Credo.Check.Readability.TrailingBlankLine},
        {Credo.Check.Readability.TrailingWhiteSpace},
        {Credo.Check.Readability.VariableNames},

        {Credo.Check.Refactor.ABCSize},
        {Credo.Check.Refactor.CyclomaticComplexity},
        {Credo.Check.Refactor.NegatedConditionsInUnless},
        {Credo.Check.Refactor.NegatedConditionsWithElse},
        {Credo.Check.Refactor.Nesting},
        {Credo.Check.Refactor.UnlessWithElse},

        {Credo.Check.Warning.IExPry},
        {Credo.Check.Warning.IoInspect},
        {Credo.Check.Warning.NameRedeclarationByAssignment},
        {Credo.Check.Warning.NameRedeclarationByCase},
        {Credo.Check.Warning.NameRedeclarationByDef},
        {Credo.Check.Warning.NameRedeclarationByFn},
        {Credo.Check.Warning.OperationOnSameValues},
        {Credo.Check.Warning.UnusedStringOperation},
      ]
    }
  ]
}
