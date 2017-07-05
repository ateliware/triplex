defmodule Triplex do
  @moduledoc """
  This is the main module of Triplex.

  The main objetive of it is to make a little bit easier to manage tenants
  through postgres db schemas or equivalents, executing queries and commands
  inside and outside the tenant without much boilerplate code.

  ## Using the tenant

  This module has useful functions to manage your tenants, like `create/1`,
  `rename/2` and `drop/1`, but if you're trying to apply the tenant to a
  query, changeset or schema, stay with your application `Repo`, sending the
  prefix. Like this:

      Repo.all(User, prefix: Triplex.to_prefix("my_tenant"))

  It's a good idea to call `Triplex.to_prefix` on your tenant name, altough is
  not required. Because, if you configured a `tenant_prefix`, this function will
  return the prefixed one.
  """

  import Mix.Ecto, only: [build_repo_priv: 1]
  alias Ecto.{
    Adapters.SQL,
    Migrator
  }

  def config, do: struct(Triplex.Config, Application.get_all_env(:triplex))

  @doc """
  This function has been deprecated.

  Use the `prefix` key in your `Repo` calls opts instead.

  For example, instead of:

      User |> Triplex.put_tenant("my_tenant") |> Repo.all()

  User:

      Repo.all(User, prefix: "my_tenant")

  Don't forget to apply the `Triplex.to_prefix/1` to transform your tenant to
  a prefix if you configured a `tenant_prefix` on your triplex configuration.

  By default, you will not need it.
  """
  def put_tenant(prefixable, map) when is_map(map) do
    put_tenant(prefixable, tenant_field(map))
  end
  def put_tenant(prefixable, nil), do: prefixable
  def put_tenant(%Ecto.Changeset{} = changeset, tenant) do
    new_changes =
      changeset.changes
      |> Map.to_list
      |> Enum.reduce(%{}, fn({key, value}, acc) ->
        new_value = case {key, value} do
          {_, list} when is_list(list) ->
            Enum.map(list, &put_tenant(&1, tenant))
          {_, %Ecto.Changeset{} = changeset} ->
            put_tenant(changeset, tenant)
          {_, value} ->
            value
        end
        Map.put(acc, key, new_value)
      end)
    changeset = %{changeset | changes: new_changes}

    %{changeset | data: put_tenant(changeset.data, tenant)}
  end
  def put_tenant(%{__struct__: _, __meta__: _} = schema, tenant) do
    warn_put_tenant_deprecated()

    schema
    |> Map.to_list
    |> Enum.reduce(%{}, fn({key, value}, acc) ->
      new_value = case {key, value} do
        {key, value} when key in [:__struct__, :__meta__] ->
          value
        {_, list} when is_list(list) ->
          Enum.map(list, &put_tenant(&1, tenant))
        {_, %{__struct__: _, __meta__: _} = struct} ->
          put_tenant(struct, tenant)
        {_, value} ->
          value
      end
      Map.put(acc, key, new_value)
    end)
    |> Ecto.put_meta(prefix: to_prefix(tenant))
  end
  def put_tenant(queryable, tenant) do
    warn_put_tenant_deprecated()

    if Ecto.Queryable.impl_for(queryable) do
      query = Ecto.Queryable.to_query(queryable)
      Map.put(query, :prefix, to_prefix(tenant))
    else
      queryable
    end
  end

  defp warn_put_tenant_deprecated() do
    IO.warn("""
    Triplex.put_tenant/2 is deprecated. Use the `prefix` key in your `Repo`
    calls opts instead.
    """)
  end

  @doc """
  Execute the given function with the given tenant set.
  """
  def with_tenant(tenant, func) do
    IO.warn("""
    Triplex.with_tenant/2 is deprecated due to its not concurrency safe nature
    """)
    old_tenant = current_tenant()
    put_current_tenant(tenant)
    try do
      func.()
    after
      put_current_tenant(old_tenant)
    end
  end

  @doc """
  Return the current tenant, set by `put_current_tenant/1`.
  """
  def current_tenant do
    IO.warn("""
    Triplex.current_tenant/0 is deprecated due to its not concurrency safe
    nature
    """)
    Process.get(__MODULE__)
  end

  @doc """
  Sets the current tenant in the current process.
  """
  def put_current_tenant(nil) do
    warn_put_current_tenant_deprecated()
    Process.put(__MODULE__, nil)
  end
  def put_current_tenant(value) when is_binary(value) do
    warn_put_current_tenant_deprecated()
    Process.put __MODULE__, value
  end
  def put_current_tenant(_) do
    raise ArgumentError, "put_current_tenant/1 only accepts binary tenants"
  end

  defp warn_put_current_tenant_deprecated() do
    IO.warn("""
    Triplex.put_current_tenant/1 is deprecated due to its not concurrency safe
    nature
    """)
  end

  @doc """
  Returns the list of reserverd tenants.

  By default, there are some limitations for the name of a tenant depending on
  the database, like "public" or anything that start with "pg_".

  You also can configure your own reserved tenant names if you want with:

      config :triplex, reserved_tenants: ["www", "api", ~r/^db\d+$/]

  Notice that you can use regexes, and they will be applied to the tenant
  names.
  """
  def reserved_tenants do
    [nil, "public", "information_schema", ~r/^pg_/ |
     config().reserved_tenants]
  end

  @doc """
  Returns if the given tenant is reserved or not.

  The function `to_prefix/1` will be applied to the tenant.
  """
  def reserved_tenant?(tenant) do
    Enum.any? reserved_tenants(), fn (i) ->
      if Regex.regex?(i) do
        Regex.match?(i, to_prefix(tenant))
      else
        i == tenant
      end
    end
  end

  @doc """
  Creates the given tenant on the given repo.

  Besides creating the database itself, this function also loads their
  structure executing all migrations from inside
  `priv/YOUR_REPO/tenant_migrations` folder.

  If the repo is not given, it uses the one you configured.
  """
  def create(tenant, repo \\ config().repo) do
    create_schema(tenant, repo, &(migrate(&1, &2)))
  end

  @doc """
  Drops the given tenant on the given repo.

  The function `to_prefix/1` will be applied to the tenant.

  If the repo is not given, it uses the one you configured.
  """
  def drop(tenant, repo \\ config().repo) do
    if reserved_tenant?(tenant) do
      {:error, reserved_message(tenant)}
    else
      sql = "DROP SCHEMA \"#{to_prefix(tenant)}\" CASCADE"
      case SQL.query(repo, sql, []) do
        {:error, e} ->
          {:error, Postgrex.Error.message(e)}
        result -> result
      end
    end
  end

  @doc """
  Renames the given tenant on the given repo.

  If any given tenant is a map, it will apply `tenant_field/1` to it and get
  the prefix from the field.

  If the repo is not given, it uses the one you configured.
  """
  def rename(old_tenant, new_tenant, repo \\ config().repo) do
    if reserved_tenant?(new_tenant) do
      {:error, reserved_message(new_tenant)}
    else
      sql = """
      ALTER SCHEMA \"#{to_prefix(old_tenant)}\"
      RENAME TO \"#{to_prefix(new_tenant)}\"
      """
      case SQL.query(repo, sql, []) do
        {:error, e} ->
          {:error, Postgrex.Error.message(e)}
        result -> result
      end
    end
  end

  @doc """
  Returns all the tenants on the given repo.

  The function `to_prefix/1` will be applied to the tenant.

  If the repo is not given, it uses the one you configured.
  """
  def all(repo \\ config().repo) do
    sql = """
      SELECT schema_name
      FROM information_schema.schemata
      """
    %Postgrex.Result{rows: result} = SQL.query!(repo, sql, [])

    result
    |> List.flatten
    |> Enum.filter(&(!reserved_tenant?(&1)))
  end

  @doc """
  Returns if the tenant exists or not on the given repo.

  The function `to_prefix/1` will be applied to the tenant.

  If the repo is not given, it uses the one you configured.
  """
  def exists?(tenant, repo \\ config().repo) do
    if reserved_tenant?(tenant) do
      false
    else
      sql = """
        SELECT COUNT(*)
        FROM information_schema.schemata
        WHERE schema_name = $1
        """
      %Postgrex.Result{rows: [[count]]} =
        SQL.query!(repo, sql, [to_prefix(tenant)])
      count == 1
    end
  end

  @doc """
  Migrates the given tenant.

  The function `to_prefix/1` will be applied to the tenant.

  If the repo is not given, it uses the one you configured.
  """
  def migrate(tenant, repo \\ config().repo) do
    try do
      {:ok, Migrator.run(repo, migrations_path(repo), :up,
                         all: true,
                         prefix: to_prefix(tenant))}
    rescue
      e in Postgrex.Error ->
        {:error, Postgrex.Error.message(e)}
    end
  end

  @doc """
  Return the path for your tenant migrations.

  If the repo is not given, it uses the one you configured.
  """
  def migrations_path(repo \\ config().repo) do
    if repo do
      Path.join(build_repo_priv(repo), "tenant_migrations")
    else
      ""
    end
  end

  @doc """
  Creates the tenant schema/database on the given repo.

  After creating it successfully, the given function callback is called with
  the tenant and the repo as arguments.

  The function `to_prefix/1` will be applied to the tenant.

  If the repo is not given, it uses the one you configured.
  """
  def create_schema(tenant, repo \\ config().repo, func \\ nil) do
    if reserved_tenant?(tenant) do
      {:error, reserved_message(tenant)}
    else
      case SQL.query(repo, "CREATE SCHEMA \"#{to_prefix(tenant)}\"", []) do
        {:ok, _} = result ->
          if func do
            func.(tenant, repo)
          else
            result
          end
        {:error, e} ->
          {:error, Postgrex.Error.message(e)}
      end
    end
  end

  @doc """
  Returns the tenant name with the given prefix.

  If the prefix is omitted, the `tenant_prefix` configuration will be used.

  The tenant can be a string, a map or a struct. For a string it will
  be used as the tenant name to concat the prefix. For a map or a struct, it
  will get the `tenant_field/0` from it to concat the prefix.
  """
  def to_prefix(tenant, prefix \\ config().tenant_prefix)
  def to_prefix(map, prefix) when is_map(map) do
    map
    |> tenant_field()
    |> to_prefix(prefix)
  end
  def to_prefix(tenant, nil), do: tenant
  def to_prefix(tenant, prefix), do: "#{prefix}#{tenant}"

  @doc """
  Returns the value of the configured tenant field on the given map.
  """
  def tenant_field(map) do
    Map.get(map, config().tenant_field)
  end

  defp reserved_message(tenant) do
    """
    You cannot create the schema because \"#{inspect(tenant)}\" is a reserved
    tenant
    """
  end
end
