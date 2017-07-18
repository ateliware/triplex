defmodule Triplex.PlugConfig do
  @moduledoc """
  This is a struct that holds basic configuration for triplex plugs.

  Here are the config keys we have:

  - `callback`: function that might be called when the plug succeeded. It
  must return a connection.
  - `failure_callback`: function that might be called when the plug failed.
  It must return a connection.
  - `tenant_handler`: function to handle te test param. The return of it will
  be used as the tenant.
  - `ensure`: flag that signs if we must ensure the tenant is loaded, and
  halt if it's not.
  - `param`: the param name to load the tenant from.
  - `assign`: the name of the assign where we must save the tenant.
  PS.: remember, the value saved when you have a `tenant_handler` configured is its return.
  """

  defstruct [
    :callback,
    :endpoint,
    :failure_callback,
    :tenant_handler,

    assign: :current_tenant,
    ensure: true,
    param: "tenant",
    session: :tenant
  ]

  def new(opts \\ []),
    do: __MODULE__ |> struct(opts) |> normalize_param()

  defp normalize_param(%{param: param} = struct) when is_atom(param),
    do: Map.put(struct, :param, Atom.to_string(param))
  defp normalize_param(struct),
    do: struct
end


