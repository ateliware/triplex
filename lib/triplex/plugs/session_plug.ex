defmodule Triplex.SessionPlug do
  @moduledoc """
  This is a basic plug that loads the current tenant assign from a given
  value set on session.

  To plug it on your router, you can use:

      plug Triplex.SessionPlug,
        session: :subdomain,
        tenant_handler: &TenantHelper.tenant_handler/1

  See `Triplex.SessionPlugConfig` to check all the allowed `config` flags.
  """

  import Triplex.Plug
  import Plug.Conn
  alias Triplex.SessionPlugConfig

  @doc false
  def init(opts), do: struct(SessionPlugConfig, opts)

  @doc false
  def call(conn, config),
    do: put_tenant(conn, get_session(conn, config.session), config)
end

