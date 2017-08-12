defmodule Triplex.PlugConfig do
  @moduledoc """
  This is a struct that holds all the configuration for triplex plugs.

  Here are the config keys we have:

  - For all plugs
    - `tenant_handler`: function to handle te test param. The return of it will
    be used as the tenant.
    - `assign`: the name of the assign where we must save the tenant.
  - For `Triplex.EnsurePlug`
    - `callback`: function that might be called when the plug succeeded. It
    must return a connection.
    - `failure_callback`: function that might be called when the plug failed.
    It must return a connection.
  - For `Triplex.ParamPlug`
    - `param`: the param name to load the tenant from.
  - For `Triplex.SessionPlug`
    - `session`: the session param name to load the tenant from.
  - For `Triplex.SubdomainPlug`
    - `endpoint`: the Phoenix.Endpoint to get the host name to dicover the
    subdomain.
  """

  defstruct [
    :callback,
    :endpoint,
    :failure_callback,
    :tenant_handler,

    assign: :current_tenant,
    param: "tenant",
    session: :tenant
  ]

  @doc """
  Creates a new `%Plug.Config{}`, normalizing the needed arguments.
  """
  def new(args \\ []),
    do: __MODULE__ |> struct(args) |> normalize_param()

  defp normalize_param(%{param: param} = struct) when is_atom(param),
    do: Map.put(struct, :param, Atom.to_string(param))
  defp normalize_param(struct),
    do: struct
end


