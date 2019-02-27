if Code.ensure_loaded?(Plug) do
  defmodule Triplex.SubdomainPlug do
    @moduledoc """
    This is a basic plug that loads the current tenant assign from a given
    value set on subdomain.

    To plug it on your router, you can use:

        plug Triplex.SubdomainPlug,
          endpoint: MyApp.Endpoint,
          tenant_handler: &TenantHelper.tenant_handler/1

    See `Triplex.SubdomainPlugConfig` to check all the allowed `config` flags.
    """

    alias Plug.Conn
    alias Triplex.SubdomainPlugConfig

    @doc false
    def init(opts), do: struct(SubdomainPlugConfig, opts)

    @doc false
    def call(conn, config), do: Triplex.Plug.put_tenant(conn, get_subdomain(conn, config), config)

    defp get_subdomain(_conn, %SubdomainPlugConfig{endpoint: nil}) do
      nil
    end

    defp get_subdomain(
           %Conn{host: host},
           %SubdomainPlugConfig{endpoint: endpoint}
         ) do
      root_host = endpoint.config(:url)[:host]

      if host in [root_host, "localhost", "127.0.0.1", "0.0.0.0"] do
        nil
      else
        String.replace(host, ~r/.?#{root_host}/, "")
      end
    end
  end
end
