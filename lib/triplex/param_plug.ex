defmodule Triplex.ParamPlug do
  @moduledoc """
  This is a basic plug that loads the current tenant assign from a given
  tenant.
  """

  import Triplex.Plug
  alias Triplex.PlugConfig

  @doc false
  def init(opts), do: PlugConfig.new(opts)

  @doc false
  def call(conn, config) do
    tenant = conn.params[config.param]

    conn
    |> put_tenant(tenant, config)
    |> do_ensure_tenant(tenant, config)
  end

  defp do_ensure_tenant(conn, tenant, %{ensure: true} = config),
    do: ensure_tenant(conn, tenant, config)
  defp do_ensure_tenant(conn, _, _),
    do: conn
end

