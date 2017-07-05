defmodule Triplex.ParamPlug do
  @moduledoc """
  This is a basic plug that loads the current tenant assign from a given
  tenant.
  """

  import Triplex.Plug
  alias Triplex.PlugConfig

  @doc false
  def init(opts), do: PlugConfig.new(opts)

  @doc false
  def call(conn, config),
    do: put_tenant(conn, conn.params[config.param], config)
end

