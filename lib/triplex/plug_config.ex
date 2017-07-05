defmodule Triplex.PlugConfig do
  @moduledoc false

  defstruct [:callback,
             :tenant_handler,
             param: "tenant",
             assign: :current_tenant]

  def new(opts \\ []),
    do: __MODULE__ |> struct(opts) |> normalize_param()

  defp normalize_param(%{param: param} = struct) when is_atom(param),
    do: Map.put(struct, :param, Atom.to_string(param))
  defp normalize_param(struct),
    do: struct
end


