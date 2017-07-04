defmodule Triplex.Config do
  defstruct [:repo, :tenant_prefix, reserved_tenants: [], tenant_field: :id]
end

