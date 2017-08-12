defmodule Triplex.PlugTest do
  use ExUnit.Case

  import Plug.Conn
  import Plug.Test
  alias Triplex.Plug
  alias Triplex.PlugConfig

  test "put_tenant/3 must set the tenant to the default assign" do
    conn =
      :get
      |> conn("/")
      |> Plug.put_tenant("power", PlugConfig.new())
    assert conn.assigns[:current_tenant] == "power"
  end

  test "put_tenant/3 must call the handler" do
    handler = fn("oi") -> "olá" end
    conn =
      :get
      |> conn("/")
      |> Plug.put_tenant("oi", PlugConfig.new(tenant_handler: handler))
    assert conn.assigns[:current_tenant] == "olá"
  end

  test "put_tenant/3 must set the tenant on the given assign" do
    conn =
      :get
      |> conn("/")
      |> Plug.put_tenant("power", PlugConfig.new(assign: :tenant))
    assert conn.assigns[:tenant] == "power"
  end

  test "put_tenant/3 must not set the tenant if it is already set" do
    conn =
      :get
      |> conn("/")
      |> assign(:current_tenant, "already_set")
      |> Plug.put_tenant("power", PlugConfig.new())
    assert conn.assigns[:current_tenant] == "already_set"
  end

  test "put_tenant/3 must not set the tenant if it is reserved" do
    conn =
      :get
      |> conn("/")
      |> Plug.put_tenant("www", PlugConfig.new())
    assert conn.assigns[:current_tenant] == nil
  end

  test "ensure_tenant/3 must halts the conn" do
    conn =
      :get
      |> conn("/")
      |> Plug.put_tenant("power", PlugConfig.new())
      |> Plug.ensure_tenant(PlugConfig.new())

    assert conn.halted == false
  end

  test "ensure_tenant/3 must call the success callback" do
    callback = fn(conn, _) -> assign(conn, :test, "blag") end
    conn =
      :get
      |> conn("/")
      |> Plug.put_tenant("power", PlugConfig.new())
      |> Plug.ensure_tenant(PlugConfig.new(callback: callback))

    assert conn.assigns[:test] == "blag"
  end

  test "ensure_tenant/3 must call the failure callback" do
    callback = fn(conn, _) -> assign(conn, :test, "blog") end
    conn =
      :get
      |> conn("/")
      |> Plug.ensure_tenant(PlugConfig.new(failure_callback: callback))

    assert conn.assigns[:test] == "blog"
  end
end
