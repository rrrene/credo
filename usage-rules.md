# Credo Usage Rules for AI Code Generation

Comprehensive rules covering all 108 Credo checks to ensure complete compliance when generating Elixir code.

## CONSISTENCY RULES (EX1001-EX1008)

### Exception Naming (EX1001)
- **MUST** use consistent exception naming patterns across codebase
- Choose either suffix pattern: `HTTPError`, `ParseError`, `ValidationError`  
- OR prefix pattern: `ErrorHTTP`, `ErrorParse`, `ErrorValidation`
- **NEVER** mix patterns: `HTTPError` + `ParseException` + `ValidationFailure`

### Line Endings (EX1002)
- **MUST** use consistent line endings throughout project
- Typically Unix `\n` (not Windows `\r\n`)
- **NEVER** mix line ending styles in same codebase

### Multi-Alias/Import/Require/Use (EX1003)
- **MUST** be consistent with single vs multi-alias syntax
- Choose ONE style and stick to it:
  - Multi: `alias Ecto.{Query, Schema, Changeset}`
  - Single: `alias Ecto.Query; alias Ecto.Schema; alias Ecto.Changeset`
- **NEVER** mix both styles in same file

### Parameter Pattern Matching (EX1004)
- **MUST** be consistent with variable placement in patterns
- Choose ONE style:
  - `{:ok, result} = call_function()`
  - `result = {:ok, value}`
- **NEVER** mix placement styles in same codebase

### Space Around Operators (EX1005)
- **MUST** be consistent with spacing around `+`, `-`, `*`, `/`, etc.
- Choose ONE style:
  - Spaced: `1 + 2 * 4 - 1`
  - Compact: `1+2*4-1`
- **NEVER** mix: `1 + 2*4` (inconsistent spacing)

### Space in Parentheses (EX1006)
- **MUST** be consistent with spacing inside `()`, `[]`, `{}`
- Choose ONE style:
  - No spaces: `func({1, 2}, :atom)`
  - With spaces: `func( { 1, 2 }, :atom )`
- **NEVER** mix: `func({1, 2 }, :atom)`

### Tabs or Spaces (EX1007)
- **MUST** use consistent indentation throughout codebase
- Typically use 2-space soft tabs in Elixir
- **NEVER** mix tabs and spaces for indentation

### Unused Variable Names (EX1008)
- **MUST** be consistent with unused variable naming
- Choose ONE style:
  - Anonymous: `_`, `_`, `_`
  - Descriptive: `_user`, `_config`, `_result`
- **NEVER** mix `_` with `_meaningful_name` in same codebase

## READABILITY RULES (EX3001-EX3035)

### Naming Conventions
- **Functions/Macros/Guards** (EX3004): `snake_case` only - `handle_request`, `validate_params`
- **Variables** (EX3031): `snake_case` only - `user_data`, `api_response`
- **Modules** (EX3010): `PascalCase` only - `MyApp.UserController`, `HTTPClient`
- **Module Attributes** (EX3008): `snake_case` - `@default_timeout`, `@api_version`
- **Predicates** (EX3016): End with `?` - `valid?/1`, `empty?/1`, `authenticated?/1`

### Documentation Requirements
- **Module Documentation** (EX3009): Every module **MUST** have `@moduledoc` or `@moduledoc false`
- **Function Specs** (EX3025): **SHOULD** add `@spec` for all public functions
- **Impl True** (EX3004): Use `@impl true` instead of specific behaviour name

### Code Organization
- **Alias Order** (EX3002): Sort aliases alphabetically within groups
- **Separate Alias/Require** (EX3021): Keep `alias` and `require` statements separate
- **Multi-Alias Avoidance** (EX3011): Avoid `alias Module.{A, B, C}` for readability
- **Strict Module Layout** (EX3026): Follow standard module organization order

### Formatting and Spacing
- **Large Numbers** (EX3005): Use underscores - `1_000_000`, `141_592_654`
- **Space After Commas** (EX3024): Always - `[1, 2, 3]`, `func(a, b, c)`
- **Trailing Blank Line** (EX3028): Files **MUST** end with newline
- **Trailing Whitespace** (EX3029): Remove all trailing whitespace
- **Redundant Blank Lines** (EX3019): Avoid multiple consecutive blank lines
- **Max Line Length** (EX3007): Keep lines under configured limit (typically 98-120)

### Pipe Operations
- **Block Pipe** (EX3003): **NEVER** pipe into `case`, `if`, `cond`, `with`
  ```elixir
  # Good
  result = fetch_data()
  case result do
    {:ok, data} -> process(data)
    {:error, _} -> handle_error()
  end
  
  # Bad
  fetch_data() |> case do
    {:ok, data} -> process(data)  
    {:error, _} -> handle_error()
  end
  ```
- **Single Pipe** (EX3023): **NEVER** use pipes for single function calls
  ```elixir
  # Good
  process_data(input)
  
  # Bad  
  input |> process_data()
  ```
- **Anonymous Function Pipes** (EX3015): **NEVER** pipe into anonymous functions
- **One-Arity Function Pipes** (EX3034): Avoid pipes for single-arity functions
- **One Pipe Per Line** (EX3035): **NEVER** chain pipes on same line
- **Single Function to Block Pipe** (EX3022): Use block syntax instead of pipes when appropriate

### Code Style
- **Parentheses in Conditions** (EX3013): Avoid unnecessary parentheses in conditions
- **Zero-Arity Def Parentheses** (EX3014): Be consistent with parentheses on zero-arity functions  
- **Prefer Unquoted Atoms** (EX3018): Use `:atom` not `:"atom"` unless necessary
- **String Sigils** (EX3027): Choose most readable sigil for use case
- **Semicolons** (EX3020): **NEVER** use semicolons to separate expressions
- **Nested Function Calls** (EX3012): Avoid deeply nested calls - use intermediate variables
- **Prefer Implicit Try** (EX3017): Use other control structures instead of explicit `try`
- **Unnecessary Alias Expansion** (EX3030): Don't expand aliases unnecessarily
- **Custom Tagged Tuples in With** (EX3032): Use explicit tagged tuples in `with` statements  
- **Single Clause With** (EX3033): **NEVER** use `with` for single clause

## REFACTOR RULES (EX4001-EX4032)

### Complexity Limits
- **ABC Size** (EX4001): Keep Assignment-Branch-Condition count < 30
- **Cyclomatic Complexity** (EX4006): Limit decision points < 9  
- **Perceived Complexity** (EX4023): Keep cognitive load manageable
- **Function Arity** (EX4010): Limit function parameters (typically < 4-5)
- **Nesting** (EX4021): Limit nesting depth < 2-3 levels
- **Module Dependencies** (EX4017): Limit module coupling

### Performance Optimizations
- **Append Single Item** (EX4002): Use `[item | list]` not `list ++ [item]`
- **Filter Count** (EX4030): Use `Enum.count(list, predicate)` not `Enum.filter |> Enum.count`
- **Filter Filter** (EX4008): Combine multiple `Enum.filter` calls into one
- **Filter Reject** (EX4009): **NEVER** use `filter` then `reject` on same data
- **Reject Filter** (EX4025): **NEVER** use `reject` then `filter` on same data  
- **Reject Reject** (EX4026): Combine multiple `Enum.reject` calls
- **Map Map** (EX4015): Combine multiple `Enum.map` calls
- **Map Join** (EX4014): Use `Enum.map_join/3` instead of `map` then `join`
- **Map Into** (EX4013): Use `Enum.into` for map-reduce patterns

### Code Quality
- **Apply** (EX4003): Use direct function calls instead of `apply/3`
- **Double Boolean Negation** (EX4007): **NEVER** use `!!var` - be explicit
  ```elixir
  # Good
  defp present?(nil), do: false  
  defp present?(false), do: false
  defp present?(_), do: true
  
  # Bad
  !!var
  ```
- **Case Trivial Matches** (EX4004): Use simple conditionals for literal matches
- **Match in Condition** (EX4016): Use `case` instead of `if` with pattern matching
- **Variable Rebinding** (EX4029): **NEVER** rebind variables in same scope
- **IO Puts** (EX4011): Use `Logger` instead of `IO.puts` in production code

### Control Flow
- **Cond Statements** (EX4005): Avoid complex `cond` - use `case` or functions
- **Unless with Else** (EX4027): **NEVER** use `unless` with `else` clause
- **Negated Conditions in Unless** (EX4018): Use positive conditions with `unless`
- **Negated Conditions with Else** (EX4019): Avoid negated conditions with `else`
- **Negated Is Nil** (EX4020): Use `is_nil(x)` instead of `!is_nil(x)`

### With Statement Rules  
- **With Clauses** (EX4032): Keep `with` statements simple - break complex ones into functions
- **Redundant With Clause Result** (EX4024): Don't return original argument from `with` clause

### Specialized Rules
- **Long Quote Blocks** (EX4012): Keep `quote` blocks short and focused
- **Pass Async in Test Cases** (EX4022): Use `async: true` when testing GenServers
- **Pipe Chain Start** (EX4031): Start pipes with actual values, not functions
- **UTC Now Truncate** (EX4028): Truncate `DateTime.utc_now()` for struct fields

## WARNING RULES (EX5001-EX5029)

### Remove Debugging Code (Critical)
- **IEx Pry** (EX5005): **NEVER** commit `IEx.pry` calls
- **IO Inspect** (EX5006): **NEVER** commit `IO.inspect` calls  
- **Dbg** (EX5003): **NEVER** commit `dbg()` or `dbg/2` calls
- Remove **ALL** debugging artifacts before committing

### Logic and Safety Issues
- **Operation on Same Values** (EX5011): Avoid redundant operations like `x == x`
- **Bool Operation on Same Values** (EX5002): Avoid `x and x`, `y or y`
- **Operation with Constant Result** (EX5012): Avoid operations that always return same value
- **Unsafe Exec** (EX5015): Validate external command execution
- **Unsafe To Atom** (EX5016): **NEVER** convert untrusted strings to atoms
- **Map Get Unsafe Pass** (EX5009): Validate `Map.get` default values

### Environment and Configuration
- **Application Config in Module Attribute** (EX5001): **NEVER** read app config into `@` attributes
- **Leaky Environment** (EX5008): **NEVER** read env vars directly in application code
- **Mix Env** (EX5010): **NEVER** use `Mix.env` in runtime code
- **Lazy Logging** (EX5007): Use lazy evaluation in Logger calls

### Unused Operations (Critical for All)
**MUST** use return values from operations on these modules:
- **Enum** (EX5017): `Enum.map`, `Enum.filter`, etc. (except `Enum.each`)
- **File** (EX5018): `File.read`, `File.write`, etc.
- **Keyword** (EX5019): `Keyword.get`, `Keyword.put`, etc.
- **List** (EX5020): `List.flatten`, `List.delete`, etc.
- **Path** (EX5021): `Path.join`, `Path.expand`, etc.
- **Regex** (EX5022): `Regex.run`, `Regex.replace`, etc.
- **String** (EX5023): `String.upcase`, `String.trim`, etc.
- **Tuple** (EX5024): `Tuple.insert_at`, `Tuple.delete_at`, etc.

```elixir
# Good - result is used
result = String.upcase(text)
send_response(result)

# Bad - result ignored  
String.upcase(text)
send_response("done")
```

### File and Testing
- **Wrong Test File Extension** (EX5025): Use `.exs` for tests, `.ex` for source
- **Forbidden Module** (EX5004): Avoid specified forbidden modules in production
- **Spec with Struct** (EX5014): **NEVER** use struct names in `@spec`
- **Raise Inside Rescue** (EX5013): Avoid raising exceptions inside rescue blocks

### Additional Warnings
- **Expensive Empty Enum Check** (EX5028): Use efficient empty checks
- **Missed Metadata Key in Logger Config** (EX5027): Include required Logger metadata
- **Unused Operation** (EX5029): General unused operation detection

## COMPREHENSIVE COMPLIANCE CHECKLIST

### Before Writing Any Elixir Code:
✅ **Naming**: `snake_case` functions/vars, `PascalCase` modules, predicates end with `?`
✅ **Consistency**: Pick ONE style for spacing, aliases, patterns and use throughout  
✅ **Documentation**: Every module has `@moduledoc`, functions have `@spec`
✅ **No Debugging**: Zero `IEx.pry`, `IO.inspect`, `dbg()` calls
✅ **Use Results**: Every operation result is captured and used
✅ **Complexity**: Functions stay simple (low ABC, cyclomatic, nesting)
✅ **Performance**: Prepend lists `[x|list]`, combine Enum operations
✅ **Pipes**: No single pipes, no block pipes, start with values
✅ **Safety**: No unsafe atom conversion, validate external inputs
✅ **File Extensions**: `.ex` source, `.exs` tests
✅ **Formatting**: Underscores in large numbers, space after commas, trailing newlines

### Code Review Questions:
1. Is every operation result used?
2. Are all debug calls removed?  
3. Is complexity within limits?
4. Are pipes used correctly?
5. Is spacing/naming consistent?
6. Are all modules documented?
7. Are performance patterns optimal?
8. Are safety practices followed?

This comprehensive guide covers all 108 Credo checks to ensure complete compliance when generating Elixir code.