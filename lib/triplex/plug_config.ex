defmodule Triplex.PlugConfig do
  @moduledoc false

  defstruct [:handler,
             param: "tenant",
             tenant_assign: :current_tenant,
             prefix_assign: :current_prefix]

  def new(opts \\ []),
    do: __MODULE__ |> struct(opts) |> normalize_param()

  defp normalize_param(%{param: param} = struct) when is_atom(param),
    do: Map.put(struct, :param, Atom.to_string(param))
  defp normalize_param(struct),
    do: struct
end


