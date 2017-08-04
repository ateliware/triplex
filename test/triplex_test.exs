defmodule TriplexTest do
  use ExUnit.Case

  import Mix.Ecto, only: [build_repo_priv: 1]

  alias Triplex.Note
  alias Triplex.TestRepo

  @migration_version 20_160_711_125_401
  @repo TestRepo
  @tenant "trilegal"

  setup do
    Ecto.Adapters.SQL.Sandbox.mode(@repo, :manual)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(@repo)
  end

  test "create/2 must create a new tenant" do
    Triplex.create("lala", @repo)
    assert Triplex.exists?("lala", @repo)
  end

  test "create/2 must return a error if the tenant already exists" do
    Triplex.create("lala", @repo)
    expected = {:error,
      "ERROR 42P06 (duplicate_schema): schema \"lala\" already exists"}
    assert ^expected = Triplex.create("lala", @repo)
  end

  test "drop/2 must drop a existent tenant" do
    Triplex.create("lala", @repo)
    Triplex.drop("lala", @repo)
    refute Triplex.exists?("lala", @repo)
  end

  test "rename/3 must drop a existent tenant" do
    Triplex.create("lala", @repo)
    Triplex.rename("lala", "lolo", @repo)
    refute Triplex.exists?("lala", @repo)
    assert Triplex.exists?("lolo", @repo)
  end

  test "all/1 must return all tenants" do
    Triplex.create("lala", @repo)
    Triplex.create("lili", @repo)
    Triplex.create("lolo", @repo)
    assert Triplex.all(@repo) == ["lala", "lili", "lolo"]
  end

  test "exists?/2 for a not created tenant returns false" do
    refute Triplex.exists?("lala", @repo)
    refute Triplex.exists?("lili", @repo)
    refute Triplex.exists?("lulu", @repo)
  end

  test "exists?/2 for a reserved tenants returns false" do
    tenants = Enum.filter Triplex.reserved_tenants, &(!Regex.regex?(&1))
    tenants = ["pg_lol", "pg_cow" | tenants]
    for tenant <- tenants do
      refute Triplex.exists?(tenant, @repo)
    end
  end

  test "migrations_path/1 must return the tenant migrations path" do
    expected = Path.join(build_repo_priv(@repo), "tenant_migrations")
    assert Triplex.migrations_path(@repo) == expected
  end

  test "migrate/2 migrates the tenant forward by default" do
    create_tenant_schema()

    assert_creates_notes_table fn ->
      {status, versions} = Triplex.migrate(@tenant, @repo)

      assert status == :ok
      assert versions == [@migration_version]
    end
  end

  test "migrate/2 returns an error tuple when it fails" do
    create_and_migrate_tenant()

    force_migration_failure fn(expected_postgres_error) ->
      {status, error_message} = Triplex.migrate(@tenant, @repo)

      assert status == :error
      assert error_message == expected_postgres_error
    end
  end

  test "to_prefix/2 must apply the given prefix to the tenant name" do
    assert Triplex.to_prefix("a", nil) == "a"
    assert Triplex.to_prefix(%{id: "a"}, nil) == "a"
    assert Triplex.to_prefix("a", "b") == "ba"
    assert Triplex.to_prefix(%{id: "a"}, "b") == "ba"
  end

  defp assert_creates_notes_table(fun) do
    assert_notes_table_is_dropped()
    fun.()
    assert_notes_table_is_present()
  end

  defp assert_notes_table_is_dropped do
    assert_raise Postgrex.Error, fn ->
      find_tenant_notes()
    end
  end

  defp assert_notes_table_is_present do
    assert find_tenant_notes() == []
  end

  defp create_and_migrate_tenant do
    Triplex.create(@tenant, @repo)
  end

  defp create_tenant_schema do
    Triplex.create_schema(@tenant, @repo)
  end

  defp find_tenant_notes do
    query = Note
            |> Ecto.Queryable.to_query
            |> Map.put(:prefix, @tenant)
    @repo.all(query)
  end

  defp force_migration_failure(migration_function) do
    sql = """
    DELETE FROM "#{@tenant}"."schema_migrations"
    """

    Ecto.Adapters.SQL.query(@repo, sql, [])

    migration_function.(
      "ERROR 42P07 (duplicate_table): relation \"notes\" already exists"
    )
  end
end

