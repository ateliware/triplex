defmodule Triplex.Config do
  @moduledoc """
  All the configuration for `Triplex` basic functionality is here:

  - `repo`: the ecto repo that will be used to execute the schema operations.
  - `tenant_prefix`: a prefix for all tenants.
  - `reserved_tenants`: a list of reserved tenants, which cannot be created
  through triplex APIs. The items here can be strings or regexes.
  - `opts`: extra options to supply for the create database query for MySQL driver
  supported options are `charset` and `collate`.
  """

  defstruct [
    :repo,
    :tenant_prefix,
    migrations_path: "tenant_migrations",
    reserved_tenants: [],
    tenant_field: :id,
    opts: [
      charset: "utf8mb4",
      collate: "utf8mb4_bin"
    ]
  ]
end
