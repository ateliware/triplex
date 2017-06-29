defmodule Triplex do
  @moduledoc """
  This is the main module of Triplex.

  The main objetive of it is to make a little bit easier to manage tenants
  through postgres db schemas or equivalents, executing queries and commands
  inside and outside the tenant without much boilerplate code.
  """

  import Mix.Ecto, only: [build_repo_priv: 1]
  alias Ecto.{
    Adapters.SQL,
    Migrator
  }

  @doc """
  Sets the tenant as the prefix for the changeset, schema or anything
  queryable.

  ## Examples

      defmodule User do
        use Ecto.Schema

        import Ecto.Changeset

        schema "users" do
          field :name, :string
        end

        def changeset(user, params) do
          cast(user, params, [:name])
        end
      end

      import Ecto.Query

      # For the changeset
      %User{}
      |> User.changeset(%{name: "John"})
      |> Triplex.put_tenant("my_tenant")
      |> Repo.insert!()

      # For the schema
      User
      |> Triplex.put_tenant("my_tenant")
      |> Repo.all()

      # For the queries
      from(u in User, select: count(id))
      |> Triplex.put_tenant("my_tenant")
      |> Repo.all()

  """
  def put_tenant(prefixable, map) when is_map(map) do
    put_tenant(prefixable, map[tenant_field()])
  end
  def put_tenant(prefixable, nil), do: prefixable
  def put_tenant(%Ecto.Changeset{} = changeset, tenant) do
    new_changes =
      changeset.changes
      |> Map.to_list
      |> Enum.reduce(%{}, fn({key, value}, acc) ->
        new_value = case {key, value} do
          {key, value} when key in [:__struct__, :__meta__] -> value
          {_, %Ecto.Changeset{} = changeset} -> put_tenant(changeset, tenant)
          {_, value} -> value
        end
        Map.put(acc, key, new_value)
      end)
    changeset = %{changeset | changes: new_changes}

    %{changeset | data: put_tenant(changeset.data, tenant)}
  end
  def put_tenant(%{__struct__: _, __meta__: _} = schema, tenant) do
    schema
    |> Map.to_list
    |> Enum.reduce(%{}, fn({key, value}, acc) ->
      new_value = case {key, value} do
        {key, value} when key in [:__struct__, :__meta__] -> value
        {_, %{__struct__: _, __meta__: _} = struct} ->
          put_tenant(struct, tenant)
        {_, value} -> value
      end
      Map.put(acc, key, new_value)
    end)
    |> Ecto.put_meta(prefix: tenant)
  end
  def put_tenant(queryable, tenant) do
    if Ecto.Queryable.impl_for(queryable) do
      query = Ecto.Queryable.to_query(queryable)
      Map.put(query, :prefix, tenant)
    else
      queryable
    end
  end

  @doc """
  Execute the given function with the given tenant set.
  """
  def with_tenant(tenant, func) do
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
  def current_tenant, do: Process.get(__MODULE__)

  @doc """
  Sets the current tenant in the current process.
  """
  def put_current_tenant(nil), do: Process.put(__MODULE__, nil)
  def put_current_tenant(value) when is_binary(value) do
    Process.put __MODULE__, value
  end
  def put_current_tenant(_) do
    raise ArgumentError, "put_current_tenant/1 only accepts binary tenants"
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
    config = Application.get_env(:triplex, :reserved_tenants) || []
    [nil, "public", "information_schema", ~r/^pg_/ | config]
  end

  @doc """
  Returns if the given tenant is reserved or not.
  """
  def reserved_tenant?(tenant) do
    Enum.any? reserved_tenants(), fn (i) ->
      if Regex.regex?(i) do
        Regex.match?(i, tenant)
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
  def create(tenant, repo \\ default_repo()) do
    create_schema(tenant, repo, &(migrate(&1, &2)))
  end

  @doc """
  Drops the given tenant on the given repo.

  If the repo is not given, it uses the one you configured.
  """
  def drop(tenant, repo \\ default_repo()) do
    if reserved_tenant?(tenant) do
      {:error, reserved_message(tenant)}
    else
      case SQL.query(repo, "DROP SCHEMA \"#{tenant}\" CASCADE", []) do
        {:error, e} ->
          {:error, Postgrex.Error.message(e)}
        result -> result
      end
    end
  end

  @doc """
  Renames the given tenant on the given repo.

  If the repo is not given, it uses the one you configured.
  """
  def rename(old_tenant, new_tenant, repo \\ default_repo()) do
    if reserved_tenant?(new_tenant) do
      {:error, reserved_message(new_tenant)}
    else
      sql = "ALTER SCHEMA \"#{old_tenant}\" RENAME TO \"#{new_tenant}\""
      case SQL.query(repo, sql, []) do
        {:error, e} ->
          {:error, Postgrex.Error.message(e)}
        result -> result
      end
    end
  end

  @doc """
  Returns all the tenants on the given repo.

  If the repo is not given, it uses the one you configured.
  """
  def all(repo \\ default_repo()) do
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

  If the repo is not given, it uses the one you configured.
  """
  def exists?(tenant, repo \\ default_repo()) do
    if reserved_tenant?(tenant) do
      false
    else
      sql = """
        SELECT COUNT(*)
        FROM information_schema.schemata
        WHERE schema_name = $1
        """
      %Postgrex.Result{rows: [[count]]} = SQL.query!(repo, sql, [tenant])
      count == 1
    end
  end

  @doc """
  Migrates the given tenant.

  If the repo is not given, it uses the one you configured.
  """
  def migrate(tenant, repo \\ default_repo()) do
    try do
      {:ok, Migrator.run(repo, migrations_path(repo), :up,
                         all: true,
                         prefix: tenant)}
    rescue
      e in Postgrex.Error ->
        {:error, Postgrex.Error.message(e)}
    end
  end

  @doc """
  Return the path for your tenant migrations.

  If the repo is not given, it uses the one you configured.
  """
  def migrations_path(repo \\ default_repo()) do
    if repo do
      Path.join(build_repo_priv(repo), "tenant_migrations")
    else
      ""
    end
  end

  defp create_schema(tenant, repo, func) do
    if reserved_tenant?(tenant) do
      {:error, reserved_message(tenant)}
    else
      case SQL.query(repo, "CREATE SCHEMA \"#{tenant}\"", []) do
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

  defp reserved_message(tenant) do
    """
    You cannot create the schema because \"#{inspect(tenant)}\" is a reserved
    tenant
    """
  end

  defp tenant_field do
    Application.get_env(:triplex, :tenant_field) || :id
  end

  defp default_repo do
    Application.get_env(:triplex, :repo)
  end
end
