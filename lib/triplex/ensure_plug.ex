defmodule Triplex.EnsurePlug do
  @moduledoc """
  This is a basic plug that ensure the tenant is loaded.

  To plug it on your router, you can use:

      plug Triplex.EnsurePlug,
        callback: &TenantHelper.callback/2
        failure_callback: &TenantHelper.failure_callback/2

  See `Triplex.PlugConfig` to check all the allowed configuration flags.
  """

  import Triplex.Plug
  alias Triplex.PlugConfig

  @doc false
  def init(opts), do: PlugConfig.new(opts)

  @doc false
  def call(conn, config) do
    ensure_tenant(conn, config)
  end
end

