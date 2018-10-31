if Code.ensure_loaded?(Plug) do
  defmodule Triplex.HeaderPlug do
    @moduledoc """
    This is a basic plug that loads the current tenant assign from a given
    header resquest.

    To plug it on your router, you can use:

        plug Triplex.HeaderPlug,
          param: :subdomain,
          tenant_handler: &TenantHelper.tenant_handler/1

    See `Triplex.HeaderPlugConfig` to check all the allowed `config` flags.
    """

    import Triplex.Plug
    import Plug.Conn
    alias Triplex.HeaderPlugConfig

    @doc false
    def init(opts), do: struct(HeaderPlugConfig, opts)

    @doc false
    def call(conn, config),
      do: put_tenant(conn, get_param(conn, config), config)

    defp get_param(conn, %HeaderPlugConfig{header: key}),
      do: get_param(conn, key)
    defp get_param(conn, key) when is_atom(key),
      do: get_param(conn, Atom.to_string(key))

    defp get_param(conn, key) do
      Enum.at(get_req_header(conn, key), 0)
    end

  end
end
