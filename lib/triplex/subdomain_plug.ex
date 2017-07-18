defmodule Triplex.SubdomainPlug do
  @moduledoc """
  This is a basic plug that loads the current tenant assign from a given
  value set on subdomain.

  To plug it on your router, you can use:

      plug Triplex.SubdomainPlug,
        endpoint: MyApp.Endpoint,
        tenant_handler: &TenantHelper.tenant_handler/1

  See `Triplex.PlugConfig` to check all the allowed configuration flags.
  """

  import Triplex.Plug
  alias Plug.Conn
  alias Triplex.PlugConfig

  @doc false
  def init(opts), do: PlugConfig.new(opts)

  @doc false
  def call(conn, config),
    do: put_tenant(conn, get_subdomain(conn, config), config)

  defp get_subdomain(_conn, %PlugConfig{endpoint: nil}) do
    nil
  end
  defp get_subdomain(%Conn{host: host}, %PlugConfig{endpoint: endpoint}) do
    root_host = endpoint.config(:url)[:host]
    if host in [root_host, "localhost", "127.0.0.1", "0.0.0.0"] do
      nil
    else
      String.replace(host, ~r/.?#{root_host}/, "")
    end
  end
end


