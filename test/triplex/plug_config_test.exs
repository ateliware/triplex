defmodule Triplex.PlugConfigTest do
  use ExUnit.Case

  alias Triplex.PlugConfig

  test "new/1 returns a new config and normalize the param" do
    assert PlugConfig.new() ==
      %PlugConfig{
        callback: nil,
        failure_callback: nil,
        tenant_handler: nil,
        ensure: true,
        param: "tenant",
        assign: :current_tenant,
      }
    assert PlugConfig.new(ensure: false, param: :oi, assign: :ho) ==
      %PlugConfig{
        callback: nil,
        failure_callback: nil,
        tenant_handler: nil,
        ensure: false,
        param: "oi",
        assign: :ho,
      }
  end
end
