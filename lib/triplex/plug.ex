defmodule Triplex.Plug do
  @moduledoc """
  This module have some basic functions for our triplex plugs.
  """

  import Plug.Conn

  @doc """
  Puts the given tenant as an assign on the given conn, but only if the
  tenant is not reserved.
  """
  def put_tenant(conn, tenant, config) do
    tenant = tenant_handler(tenant, config.tenant_handler)
    if Triplex.reserved_tenant?(tenant) do
      conn
    else
      conn
      |> assign(config.assign, tenant)
      |> callback(tenant, config.callback)
    end
  end

  defp tenant_handler(tenant, nil),
    do: tenant
  defp tenant_handler(tenant, tenant_handler) when is_function(tenant_handler),
    do: tenant_handler.(tenant)

  defp callback(conn, _, nil),
    do: conn
  defp callback(conn, tenant, callback) when is_function(callback),
    do: callback.(conn, tenant)
end

