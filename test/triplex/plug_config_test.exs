defmodule Triplex.PlugConfigTest do
  use ExUnit.Case

  alias Triplex.PlugConfig

  test "new/0 returns a new config with default values set" do
    assert PlugConfig.new() ==
      %PlugConfig{
        callback: nil,
        failure_callback: nil,
        tenant_handler: nil,
        param: "tenant",
        assign: :current_tenant,
      }
  end

  test "new/1 returns a new config and normalize the param" do
    assert PlugConfig.new(param: :oi, assign: :ho) ==
      %PlugConfig{
        callback: nil,
        failure_callback: nil,
        tenant_handler: nil,
        param: "oi",
        assign: :ho,
      }
  end
end
