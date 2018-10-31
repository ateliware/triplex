defmodule Triplex.HeaderPlugTest do
  use ExUnit.Case

  import Plug.Test
  import Plug.Conn
  alias Triplex.HeaderPlug

  test "call/2 must set the tenant to assign" do
    conn =
      :get
      |> conn("/")
      |> put_req_header( "tenant", "oi")
      |> HeaderPlug.call(HeaderPlug.init([]))
    assert conn.assigns[:current_tenant] == "oi"
  end

  test "call/2 must call the tenant handler to the a good tenant" do
    handler = fn("oi") -> "olá" end
    conn =
      :get
      |> conn("/")
      |> put_req_header( "tenant" , "oi")
      |> HeaderPlug.call(HeaderPlug.init(tenant_handler: handler))
    assert conn.assigns[:current_tenant] == "olá"
  end

  test "call/2 must read from the given header and write in the given assign" do
    conn =
      conn(:get, "/")
      |> put_req_header("ten", "tchau")
      |> HeaderPlug.call(HeaderPlug.init(header: :ten, assign: :tenant))
    assert conn.assigns[:tenant] == "tchau"
  end
end

