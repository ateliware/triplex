defmodule Triplex.SubdomainPlugTest do
  use ExUnit.Case

  import Plug.Test
  import Plug.Conn
  alias Triplex.SubdomainPlug
  alias Triplex.FakeEndpoint

  test "put_tenant/2 must set the tenant to the given assign" do
    conn =
      :get
      |> conn("/")
      |> (&(%{&1 | host: "oi.lvh.me"})).()
      |> SubdomainPlug.call(SubdomainPlug.init(endpoint: FakeEndpoint))
    assert conn.assigns[:current_tenant] == "oi"

    handler = fn("oi") -> "olá" end
    conn =
      :get
      |> conn("/")
      |> (&(%{&1 | host: "oi.lvh.me"})).()
      |> SubdomainPlug.call(SubdomainPlug.init(endpoint: FakeEndpoint, tenant_handler: handler))
    assert conn.assigns[:current_tenant] == "olá"

    callback = fn(conn, _) -> assign(conn, :lala, "lolo") end
    conn =
      :get
      |> conn("/")
      |> (&(%{&1 | host: "lele.lvh.me"})).()
      |> SubdomainPlug.call(SubdomainPlug.init(endpoint: FakeEndpoint, callback: callback))

    assert conn.assigns[:current_tenant] == "lele"
    assert conn.assigns[:lala] == "lolo"

    callback = fn(conn, _) -> assign(conn, :lele, "lili") end
    conn =
      :get
      |> conn("/")
      |> (&(%{&1 | host: "lvh.me"})).()
      |> SubdomainPlug.call(SubdomainPlug.init(endpoint: FakeEndpoint, failure_callback: callback))

    assert conn.assigns[:current_tenant] == nil
    assert conn.assigns[:lele] == "lili"
    assert conn.halted == true
  end
end



