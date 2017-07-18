defmodule Triplex.SessionPlug do
  @moduledoc """
  This is a basic plug that loads the current tenant assign from a given
  value set on session.

  To plug it on your router, you can use:

      plug Triplex.SessionPlug,
        session: :subdomain,
        tenant_handler: &TenantHelper.tenant_handler/1,
        callback: &TenantHelper.callback/2
        failure_callback: &TenantHelper.failure_callback/2

  See `Triplex.PlugConfig` to check all the allowed configuration flags.
  """

  import Triplex.Plug
  import Plug.Conn
  alias Triplex.PlugConfig

  @doc false
  def init(opts), do: PlugConfig.new(opts)

  @doc false
  def call(conn, config) do
    tenant = get_session(conn, config.session)

    conn
    |> put_tenant(tenant, config)
    |> do_ensure_tenant(tenant, config)
  end

  defp do_ensure_tenant(conn, tenant, %{ensure: true} = config),
    do: ensure_tenant(conn, tenant, config)
  defp do_ensure_tenant(conn, _, _),
    do: conn
end

