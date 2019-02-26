defmodule Triplex.ParamPlugTest do
  use ExUnit.Case

  import Plug.Test
  alias Triplex.ParamPlug

  test "call/2 must set the tenant to assign" do
    conn =
      :get
      |> conn("/", tenant: "oi")
      |> ParamPlug.call(ParamPlug.init([]))

    assert conn.assigns[:current_tenant] == "oi"
  end

  test "call/2 must call the tenant handler to the a good tenant" do
    handler = fn "oi" -> "olá" end

    conn =
      :get
      |> conn("/", tenant: "oi")
      |> ParamPlug.call(ParamPlug.init(tenant_handler: handler))

    assert conn.assigns[:current_tenant] == "olá"
  end

  test "call/2 must read from the given param and write in the given assign" do
    conn =
      :get
      |> conn("/", ten: "tchau")
      |> ParamPlug.call(ParamPlug.init(param: :ten, assign: :tenant))

    assert conn.assigns[:tenant] == "tchau"
  end
end
