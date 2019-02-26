defmodule Triplex.ParamPlugConfig do
  @moduledoc """
  This is a struct that holds all configuration for `Triplex.ParamPlug`.

  Here are the config keys allowed:

  - `tenant_handler`: function to handle the tenant param. Its return will
  be used as the tenant.
  - `assign`: the name of the assign where we must save the tenant.
  - `param`: the param name to load the tenant from.
  """

  defstruct [:tenant_handler, assign: :current_tenant, param: "tenant"]
end
