if Code.ensure_loaded?(Plug) do
  defmodule Triplex.Plug do
    @moduledoc """
    This module have some basic functions for our triplex plugs.

    The plugs we have for now are:

    - `Triplex.ParamPlug` - loads the tenant from a body or query param
    - `Triplex.SessionPlug` - loads the tenant from a session param
    - `Triplex.SubdomainPlug` - loads the tenant from the url subdomain
    - `Triplex.EnsurePlug` - ensures the current tenant is loaded and halts if not
    """

    @raw_tenant_assign :raw_current_tenant

    @doc """
    Puts the given `tenant` as an assign on the given `conn`, but only if the
    tenant is not reserved.

    The `config` map/struct must have:

    - `tenant_handler`: function to handle the tenant param. Its return will
    be used as the tenant.
    - `assign`: the name of the assign where we must save the tenant.
    """
    def put_tenant(conn, tenant, config) do
      if conn.assigns[config.assign] do
        conn
      else
        conn = Plug.Conn.assign(conn, @raw_tenant_assign, tenant)
        tenant = tenant_handler(tenant, config.tenant_handler)

        if Triplex.reserved_tenant?(tenant) do
          conn
        else
          Plug.Conn.assign(conn, config.assign, tenant)
        end
      end
    end

    @doc """
    Ensure the tenant is loaded, and if not, halts the `conn`.

    The `config` map/struct must have:

    - `assign`: the name of the assign where we must save the tenant.
    """
    def ensure_tenant(conn, config) do
      if loaded_tenant = conn.assigns[config.assign] do
        callback(conn, loaded_tenant, config.callback)
      else
        conn
        |> callback(conn.assigns[@raw_tenant_assign], config.failure_callback)
        |> Plug.Conn.halt()
      end
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
end
