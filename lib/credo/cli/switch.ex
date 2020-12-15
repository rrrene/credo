defmodule Credo.CLI.Switch do
  defstruct name: nil,
            type: :string,
            alias: nil

  def boolean(name, keywords \\ []) when is_atom(name) or is_binary(name) do
    from_keywords(name, Keyword.put(keywords, :type, :boolean))
  end

  def string(name, keywords \\ []) when is_atom(name) or is_binary(name) do
    from_keywords(name, Keyword.put(keywords, :type, :string))
  end

  def keep(name, keywords \\ []) when is_atom(name) or is_binary(name) do
    from_keywords(name, Keyword.put(keywords, :type, :keep))
  end

  def ensure(%__MODULE__{} = switch), do: switch
  def ensure(%{} = switch), do: from_map(switch)

  def ensure(switch) do
    raise("Expected Credo.CLI.Switch, got: #{inspect(switch, pretty: true)}")
  end

  defp from_map(%{name: name} = switch) when is_atom(name) or is_binary(name) do
    name = String.to_atom(to_string(switch.name))

    struct(__MODULE__, %{switch | name: name})
  end

  defp from_keywords(name, keywords) when is_atom(name) or is_binary(name) do
    name = String.to_atom(to_string(name))
    type = keywords[:type] || :string

    keywords =
      keywords
      |> Keyword.put(:type, type)
      |> Keyword.put(:name, name)

    struct(__MODULE__, keywords)
  end
end
