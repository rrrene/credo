defmodule Credo.Check.Params do

  @doc "Returns the given `field`'s params value."
  def get(params, field, default_params \\ []) when is_list(params) do
    case params[field] do
      nil ->
        default_params[field]
      val ->
        val
    end
  end

end
