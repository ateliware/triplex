defmodule Triplex.SubdomainPlugTest do
  use ExUnit.Case

  import Plug.Test
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
end



