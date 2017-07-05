defmodule Triplex.ParamPlugTest do
  use ExUnit.Case

  import Plug.Test
  import Plug.Conn
  alias Triplex.ParamPlug

  test "put_tenant/2 must set the tenant to the given assign" do
    conn =
      :get
      |> conn("/", tenant: "oi")
      |> ParamPlug.call(ParamPlug.init([]))
    assert conn.assigns[:current_tenant] == "oi"

    handler = fn("oi") -> "olá" end
    conn =
      :get
      |> conn("/", tenant: "oi")
      |> ParamPlug.call(ParamPlug.init(tenant_handler: handler))
    assert conn.assigns[:current_tenant] == "olá"

    conn =
      :get
      |> conn("/", ten: "tchau")
      |> ParamPlug.call(ParamPlug.init(param: :ten, assign: :tenant))
    assert conn.assigns[:tenant] == "tchau"

    callback = fn(conn, _) -> assign(conn, :lala, "lolo") end
    conn =
      :get
      |> conn("/", tenant: "lele")
      |> ParamPlug.call(ParamPlug.init(callback: callback))

    assert conn.assigns[:current_tenant] == "lele"
    assert conn.assigns[:lala] == "lolo"

    callback = fn(conn, _) -> assign(conn, :lele, "lili") end
    conn =
      :get
      |> conn("/", lol: "")
      |> ParamPlug.call(ParamPlug.init(failure_callback: callback))

    assert conn.assigns[:current_tenant] == nil
    assert conn.assigns[:lele] == "lili"
    assert conn.halted == true
  end
end

