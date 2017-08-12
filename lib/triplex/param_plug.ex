defmodule Triplex.ParamPlug do
  @moduledoc """
  This is a basic plug that loads the current tenant assign from a given
  param.

  To plug it on your router, you can use:

      plug Triplex.ParamPlug,
        param: :subdomain,
        tenant_handler: &TenantHelper.tenant_handler/1

  See `Triplex.PlugConfig` to check all the allowed `config` flags.
  """

  import Triplex.Plug
  alias Triplex.PlugConfig

  @doc false
  def init(opts), do: PlugConfig.new(opts)

  @doc false
  def call(conn, config),
    do: put_tenant(conn, conn.params[config.param], config)
end

