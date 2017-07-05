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
    if Triplex.reserved_tenant?(tenant) do
      conn
    else
      conn
      |> assign(config.tenant_assign, tenant)
      |> assign(config.prefix_assign, Triplex.to_prefix(tenant))
      |> call_handler(tenant, config.handler)
    end
  end

  defp call_handler(conn, _, nil),
    do: conn
  defp call_handler(conn, tenant, handler) when is_function(handler),
    do: handler.(conn, tenant)
end

