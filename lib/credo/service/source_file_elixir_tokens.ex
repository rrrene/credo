defmodule Credo.Service.SourceFileElixirTokens do
  @moduledoc false

  # Caches the result of `Credo.Code.to_tokens/1`
  # (`:elixir_tokenizer` tokens, not CredoTokenizer tokens)
  # per source file.

  use Credo.Service.ETSTableHelper
end
