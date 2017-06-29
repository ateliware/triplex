defmodule Triplex do
  @moduledoc """
  This lib is basically a wrapper to the prefix ecto's functionality.

  The main objetive of it is to make a little bit easier to manage tenants
  through postgres db schemas.
  """

  import Mix.Ecto, only: [build_repo_priv: 1]
  alias Ecto.{
    Adapters.SQL,
    Migrator
  }

  def with_tenant(tenant, func) do
    old_tenant = current_tenant()
    put_current_tenant(tenant)
    try do
      func.()
    after
      put_current_tenant(old_tenant)
    end
  end

  def current_tenant, do: Process.get(__MODULE__)

  def put_current_tenant(nil), do: Process.put(__MODULE__, nil)
  def put_current_tenant(value) when is_binary(value) do
    Process.put __MODULE__, value
  end
  def put_current_tenant(_) do
    raise ArgumentError, "put_current_tenant/1 only accepts binary tenants"
  end

  def prefix_excluded_models do
    Application.get_env(:triplex, :prefix_excluded_models)
  end

  def default_repo do
    Application.get_env(:triplex, :repo)
  end

  def reserved_tenants do
    config = Application.get_env(:triplex, :reserved_tenants) || []
    [nil, "public", "information_schema", ~r/^pg_/ | config]
  end

  def reserved_tenant?(tenant) do
    Enum.any? reserved_tenants(), fn (i) ->
      if Regex.regex?(i) do
        Regex.match?(i, tenant)
      else
        i == tenant
      end
    end
  end

  def reserved_message(tenant) do
    """
    You cannot create the schema because \"#{inspect(tenant)}\" is a reserved
    tenant
    """
  end

  def create(tenant, repo \\ default_repo()) do
    create_schema(tenant, repo, &(migrate(&1, &2)))
  end

  def create_schema(tenant, repo \\ default_repo(), func \\ nil) do
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

  def migrations_path(repo \\ default_repo()) do
    if repo do
      Path.join(build_repo_priv(repo), "tenant_migrations")
    else
      ""
    end
  end

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
end
