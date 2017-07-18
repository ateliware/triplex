defmodule Triplex.SessionPlugTest do
  use ExUnit.Case

  import Plug.Test
  import Plug.Conn
  alias Triplex.SessionPlug

  test "put_tenant/2 must set the tenant to the given assign" do
    conn =
      :get
      |> conn("/")
      |> init_test_session(%{tenant: "oi"})
      |> SessionPlug.call(SessionPlug.init([]))
    assert conn.assigns[:current_tenant] == "oi"

    handler = fn("oi") -> "olá" end
    conn =
      :get
      |> conn("/")
      |> init_test_session(%{tenant: "oi"})
      |> SessionPlug.call(SessionPlug.init(tenant_handler: handler))
    assert conn.assigns[:current_tenant] == "olá"

    conn =
      :get
      |> conn("/")
      |> init_test_session(%{ten: "tchau"})
      |> SessionPlug.call(SessionPlug.init(session: :ten, assign: :tenant))
    assert conn.assigns[:tenant] == "tchau"

    callback = fn(conn, _) -> assign(conn, :lala, "lolo") end
    conn =
      :get
      |> conn("/")
      |> init_test_session(%{tenant: "lele"})
      |> SessionPlug.call(SessionPlug.init(callback: callback))

    assert conn.assigns[:current_tenant] == "lele"
    assert conn.assigns[:lala] == "lolo"

    callback = fn(conn, _) -> assign(conn, :lele, "lili") end
    conn =
      :get
      |> conn("/")
      |> init_test_session(%{lol: ""})
      |> SessionPlug.call(SessionPlug.init(failure_callback: callback))

    assert conn.assigns[:current_tenant] == nil
    assert conn.assigns[:lele] == "lili"
    assert conn.halted == true
  end
end


