if Code.ensure_loaded?(Plug) do
  defmodule Triplex.EnsurePlug do
    @moduledoc """
    This is a basic plug that ensure the tenant is loaded.

    To plug it on your router, you can use:

        plug Triplex.EnsurePlug,
          callback: &TenantHelper.callback/2
          failure_callback: &TenantHelper.failure_callback/2

    See `Triplex.EnsurePlugConfig` to check all the allowed `config` flags.
    """

    alias Triplex.EnsurePlugConfig
    alias Triplex.Plug

    @doc false
    def init(opts), do: struct(EnsurePlugConfig, opts)

    @doc false
    def call(conn, config), do: Plug.ensure_tenant(conn, config)
  end
end
