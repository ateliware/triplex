defmodule TriplexTest do
  use ExUnit.Case

  alias Triplex.Note
  alias Triplex.TestRepo

  @migration_version 20_160_711_125_401
  @repo TestRepo
  @tenant "trilegal"

  setup do
    if @repo.__adapter__ == Ecto.Adapters.MySQL do
      # DDL operations in MySQL automatically issue a transaction commit.
      # This is not compatible with the :manual/:shared sandbox mode, which
      # wraps each checked out connection in a transaction
      # Therefore, when dealing with DDL operations in MySQL in a test, we have
      # to "clean up" ourselves
      Ecto.Adapters.SQL.Sandbox.mode(@repo, :auto)
      drop_tenants = fn ->
        Triplex.drop("lala", @repo)
        Triplex.drop("lili", @repo)
        Triplex.drop("lolo", @repo)
        Triplex.drop(@tenant, @repo)
      end
      drop_tenants.()
      on_exit drop_tenants
      :ok
    else
      Ecto.Adapters.SQL.Sandbox.mode(@repo, :manual)
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(@repo)
    end
  end

  test "create/2 must create a new tenant" do
    Triplex.create("lala", @repo)
    assert Triplex.exists?("lala", @repo)
  end

  test "create/2 must return a error if the tenant already exists" do
    Triplex.create("lala", @repo)
    assert {:error, msg} = Triplex.create("lala", @repo)
    if @repo.__adapter__ == Ecto.Adapters.MySQL do
      assert msg =~
        "Can't create database 'lala'; database exists"
    else
      assert msg ==
        "ERROR 42P06 (duplicate_schema): schema \"lala\" already exists"
    end
  end

  test "create/2 must return a error if the tenant is reserved" do
    assert {:error, msg} = Triplex.create("www", @repo)
    assert msg ==
      """
      You cannot create the schema because \"www\" is a reserved
      tenant
      """
  end

  test "drop/2 must drop a existent tenant" do
    Triplex.create("lala", @repo)
    Triplex.drop("lala", @repo)
    refute Triplex.exists?("lala", @repo)
  end

  test "rename/3 must drop a existent tenant" do
    if @repo.__adapter__ != Ecto.Adapters.MySQL do
      Triplex.create("lala", @repo)
      Triplex.rename("lala", "lolo", @repo)
      refute Triplex.exists?("lala", @repo)
      assert Triplex.exists?("lolo", @repo)
    end
  end

  test "all/1 must return all tenants" do
    Triplex.create("lala", @repo)
    Triplex.create("lili", @repo)
    Triplex.create("lolo", @repo)
    assert MapSet.new(Triplex.all(@repo)) == MapSet.new(["lala", "lili", "lolo"])
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

  test "reserved_tenant?/1 returns if the given tenant is reserved" do
    assert Triplex.reserved_tenant?(%{id: "www"}) == true
    assert Triplex.reserved_tenant?("www") == true
    assert Triplex.reserved_tenant?(%{id: "bla"}) == false
    assert Triplex.reserved_tenant?("bla") == false
  end

  test "migrations_path/1 must return the tenant migrations path" do
    expected = Application.app_dir(:triplex, "priv/test_repo/tenant_migrations")
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

    force_migration_failure fn(expected_error) ->
      {status, error_message} = Triplex.migrate(@tenant, @repo)
      assert status == :error
      assert error_message == expected_error
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
    if @repo.__adapter__ == Ecto.Adapters.MySQL do
      assert_raise Mariaex.Error, fn ->
        find_tenant_notes()
      end
    else
      assert_raise Postgrex.Error, fn ->
        find_tenant_notes()
      end
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
    sql = case @repo.__adapter__ do
      Ecto.Adapters.MySQL -> """
      DELETE FROM #{@tenant}.schema_migrations
      """
      _ -> """
      DELETE FROM "#{@tenant}"."schema_migrations"
      """
    end
    {:ok, _ } = Ecto.Adapters.SQL.query(@repo, sql, [])

    if @repo.__adapter__ == Ecto.Adapters.MySQL do 
      migration_function.(
        "(1050): Table 'notes' already exists"
      )
    else
      migration_function.(
        "ERROR 42P07 (duplicate_table): relation \"notes\" already exists"
      )
    end
  end
end

