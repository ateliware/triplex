defmodule Triplex.PlugConfigTest do
  use ExUnit.Case

  alias Triplex.PlugConfig

  test "new/1 returns a new config and normalize the param" do
    assert PlugConfig.new() ==
      %PlugConfig{handler: nil, param: "tenant", assign: :current_tenant}
    assert PlugConfig.new(param: :oi, assign: :tchau) ==
      %PlugConfig{handler: nil, param: "oi", assign: :tchau}
  end
end
