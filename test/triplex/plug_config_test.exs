defmodule Triplex.PlugConfigTest do
  use ExUnit.Case

  alias Triplex.PlugConfig

  test "new/1 returns a new config and normalize the param" do
    assert PlugConfig.new() ==
      %PlugConfig{
        handler: nil,
        param: "tenant",
        tenant_assign: :current_tenant,
        prefix_assign: :current_prefix
      }
    assert PlugConfig.new(param: :oi, tenant_assign: :ho, prefix_assign: :ha) ==
      %PlugConfig{
        handler: nil,
        param: "oi",
        tenant_assign: :ho,
        prefix_assign: :ha
      }
  end
end
