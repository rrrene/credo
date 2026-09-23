defmodule Credo.Service.SourceFileCredoTokens do
  @moduledoc false

  # Caches the result of `Credo.Code.Token.tokenize!/1`
  # (`CredoTokenizer` tokens, not Elixir tokenizer tokens)
  # per source file.

  use Credo.Service.ETSTableHelper
end
