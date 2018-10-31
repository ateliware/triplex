defmodule Triplex.EnsurePlugConfig do
  @moduledoc """
  This is a struct that holds the configuration for `Triplex.EnsurePlug`.

  Here are the config keys allowed:

  - `assign`: the name of the assign where we must save the tenant.
  - `callback`: function that might be called when the plug succeeded. It
  must return a connection.
  - `failure_callback`: function that might be called when the plug failed.
  It must return a connection.
  """

  defstruct [:callback, :failure_callback, assign: :current_tenant]
end


