defmodule Triplex.SubdomainPlugTest do
  use ExUnit.Case

  import Plug.Test
  import Plug.Conn
  alias Triplex.SubdomainPlug
  alias Triplex.FakeEndpoint

  test "call/2 must set the tenant" do
    conn =
      :get
      |> conn("/")
      |> (&(%{&1 | host: "oi.lvh.me"})).()
      |> SubdomainPlug.call(SubdomainPlug.init(endpoint: FakeEndpoint))
    assert conn.assigns[:current_tenant] == "oi"
  end

  test "call/2 must call the handler" do
    handler = fn("oi") -> "olá" end
    conn =
      :get
      |> conn("/")
      |> (&(%{&1 | host: "oi.lvh.me"})).()
      |> SubdomainPlug.call(SubdomainPlug.init(endpoint: FakeEndpoint, tenant_handler: handler))
    assert conn.assigns[:current_tenant] == "olá"
  end

  test "call/2 must call the success callback" do
    callback = fn(conn, _) -> assign(conn, :lala, "lolo") end
    conn =
      :get
      |> conn("/")
      |> (&(%{&1 | host: "lele.lvh.me"})).()
      |> SubdomainPlug.call(SubdomainPlug.init(endpoint: FakeEndpoint, callback: callback))

    assert conn.assigns[:current_tenant] == "lele"
    assert conn.assigns[:lala] == "lolo"
  end

  test "call/2 must call the failure callback" do
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



