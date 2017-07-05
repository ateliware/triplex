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

    conn =
      :get
      |> conn("/", ten: "tchau")
      |> ParamPlug.call(ParamPlug.init(param: :ten, assign: :tenant))
    assert conn.assigns[:tenant] == "tchau"

    handler = fn(conn, _) -> assign(conn, :lala, "lolo") end
    conn =
      :get
      |> conn("/", tenant: "lele")
      |> ParamPlug.call(ParamPlug.init(handler: handler))

    assert conn.assigns[:current_tenant] == "lele"
    assert conn.assigns[:lala] == "lolo"
  end
end

