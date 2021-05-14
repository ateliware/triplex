defmodule Triplex.Config do
  @moduledoc """
  All the configuration for `Triplex` basic functionality is here:

  - `repo`: the ecto repo that will be used to execute the schema operations.
  - `tenant_prefix`: a prefix for all tenants.
  - `reserved_tenants`: a list of reserved tenants, which cannot be created
  through triplex APIs. The items here can be strings or regexes.
  - `tenant_field`: an atom with the name of the field to get the tenant name
  if the given tenant is a struct. By default it's `:id`.
  - `mysql`: extra options to supply for the create database query for MySQL driver.
  The SQL standard allows a DEFAULT CHARACTER SET clause in CREATE SCHEMA than are presently accepted by PostgreSQL.
  supported options are `charset` and `collate`.
  """

  defstruct [
    :repo,
    :tenant_prefix,
    migrations_path: "tenant_migrations",
    reserved_tenants: [],
    tenant_field: :id,
    tenant_table: :tenants,
    mysql: [
      charset: "utf8mb4",
      collate: "utf8mb4_bin"
    ]
  ]
end
