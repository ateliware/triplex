defmodule Triplex.Plug do
  @moduledoc """
  This module have some basic functions for our triplex plugs.
  """

  import Plug.Conn
  alias Triplex.PlugConfig

  @raw_tenant_assign :raw_current_tenant

  @doc """
  Puts the given tenant as an assign on the given conn, but only if the
  tenant is not reserved.

  See `Triplex.PlugConfig` to the allowed configuration flags.
  """
  def put_tenant(conn, tenant, config) do
    if conn.assigns[config.assign] do
      conn
    else
      conn = assign(conn, @raw_tenant_assign, tenant)
      tenant = tenant_handler(tenant, config.tenant_handler)
      if Triplex.reserved_tenant?(tenant) do
        conn
      else
        assign(conn, config.assign, tenant)
      end
    end
  end

  @doc """
  Ensure the tenant is loaded, and if not, halts the conn.

  See `Triplex.PlugConfig` to the allowed configuration flags.
  """
  def ensure_tenant(conn, %PlugConfig{ensure: true} = config) do
    if loaded_tenant = conn.assigns[config.assign] do
      callback(conn, loaded_tenant, config.callback)
    else
      conn
      |> callback(conn.assigns[@raw_tenant_assign], config.failure_callback)
      |> halt()
    end
  end
  def ensure_tenant(conn, _) do
    conn
  end

  defp tenant_handler(tenant, nil),
    do: tenant
  defp tenant_handler(tenant, handler) when is_function(handler),
    do: handler.(tenant)

  defp callback(conn, _, nil),
    do: conn
  defp callback(conn, tenant, callback) when is_function(callback),
    do: callback.(conn, tenant)
end

