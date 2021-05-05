defmodule TriplexTest do
  use ExUnit.Case

  alias Triplex.Note
  alias Triplex.PGTestRepo
  alias Triplex.MSTestRepo

  @migration_version 20_160_711_125_401
  @repos [PGTestRepo, MSTestRepo]
  @tenant "trilegal"

  setup do
    for repo <- @repos do
      Ecto.Adapters.SQL.Sandbox.mode(repo, :auto)

      drop_tenants = fn ->
        Triplex.drop("lala", repo)
        Triplex.drop("lili", repo)
        Triplex.drop("lolo", repo)
        Triplex.drop(@tenant, repo)
      end

      drop_tenants.()
      on_exit(drop_tenants)
    end

    :ok
  end

  test "create/2 must create a new tenant" do
    for repo <- @repos do
      Triplex.create("lala", repo)
      assert Triplex.exists?("lala", repo)
    end
  end

  test "create/2 must return a error if the tenant already exists" do
    assert {:ok, _} = Triplex.create("lala", PGTestRepo)

    assert {:error, "ERROR 42P06 (duplicate_schema) schema \"lala\" already exists"} =
             Triplex.create("lala", PGTestRepo)

    assert {:ok, _} = Triplex.create("lala", MSTestRepo)

    assert {:error, "(1007) (ER_DB_CREATE_EXISTS) Can't create database 'lala'; database exists"} =
             Triplex.create("lala", MSTestRepo)
  end

  test "create/2 must return a error if the tenant is reserved" do
    for repo <- @repos do
      assert {:error, msg} = Triplex.create("www", repo)

      assert msg ==
               """
               You cannot create the schema because \"www\" is a reserved
               tenant
               """
    end
  end

  test "create_schema/3 must rollback the tenant creation when function fails" do
    for repo <- @repos do
      result = {:error, "message"}

      assert Triplex.create_schema("lala", repo, fn "lala", ^repo ->
               assert Triplex.exists?("lala", repo)
               result
             end) == result

      refute Triplex.exists?("lala", repo)
    end
  end

  test "drop/2 must drop a existent tenant" do
    for repo <- @repos do
      Triplex.create("lala", repo)
      Triplex.drop("lala", repo)
      refute Triplex.exists?("lala", repo)
    end
  end

  test "rename/3 must drop a existent tenant" do
    Triplex.create("lala", PGTestRepo)
    Triplex.rename("lala", "lolo", PGTestRepo)
    refute Triplex.exists?("lala", PGTestRepo)
    assert Triplex.exists?("lolo", PGTestRepo)
  end

  test "all/1 must return all tenants" do
    for repo <- @repos do
      Triplex.create("lala", repo)
      Triplex.create("lili", repo)
      Triplex.create("lolo", repo)

      assert MapSet.subset?(MapSet.new(["lala", "lili", "lolo"]), MapSet.new(Triplex.all(repo)))
    end
  end

  test "exists?/2 for a not created tenant returns false" do
    for repo <- @repos do
      refute Triplex.exists?("lala", repo)
      refute Triplex.exists?("lili", repo)
      refute Triplex.exists?("lulu", repo)
    end
  end

  test "exists?/2 for a reserved tenants returns false" do
    for repo <- @repos do
      tenants = Enum.filter(Triplex.reserved_tenants(), &(!Regex.regex?(&1)))
      tenants = ["pg_lol", "pg_cow" | tenants]

      for tenant <- tenants do
        refute Triplex.exists?(tenant, repo)
      end
    end
  end

  test "reserved_tenant?/1 returns if the given tenant is reserved" do
    assert Triplex.reserved_tenant?(%{id: "www"}) == true
    assert Triplex.reserved_tenant?("www") == true
    assert Triplex.reserved_tenant?(%{id: "bla"}) == false
    assert Triplex.reserved_tenant?("bla") == false
  end

  test "migrations_path/1 must return the tenant migrations path" do
    for repo <- @repos do
      folder = repo |> Module.split() |> List.last() |> Macro.underscore()
      expected = Application.app_dir(:triplex, "priv/#{folder}/tenant_migrations")
      assert Triplex.migrations_path(repo) == expected
    end
  end

  test "migrate/2 migrates the tenant forward by default" do
    for repo <- @repos do
      create_tenant_schema(repo)

      assert_creates_notes_table(repo, fn ->
        {status, versions} = Triplex.migrate(@tenant, repo)

        assert status == :ok
        assert versions == [@migration_version]
      end)
    end
  end

  test "migrate/2 returns an error tuple when it fails" do
    for repo <- @repos do
      create_and_migrate_tenant(repo)

      force_migration_failure(repo, fn expected_error ->
        {status, error_message} = Triplex.migrate(@tenant, repo)
        assert status == :error
        assert error_message == expected_error
      end)
    end
  end

  test "to_prefix/2 must apply the given prefix to the tenant name" do
    assert Triplex.to_prefix("a", nil) == "a"
    assert Triplex.to_prefix(%{id: "a"}, nil) == "a"
    assert Triplex.to_prefix("a", "b") == "ba"
    assert Triplex.to_prefix(%{id: "a"}, "b") == "ba"
  end

  defp assert_creates_notes_table(repo, fun) do
    assert_notes_table_is_dropped(repo)
    fun.()
    assert_notes_table_is_present(repo)
  end

  defp assert_notes_table_is_dropped(repo) do
    error =
      case repo.__adapter__() do
        Ecto.Adapters.MyXQL -> MyXQL.Error
        Ecto.Adapters.Postgres -> Postgrex.Error
      end

    assert_raise error, fn ->
      find_tenant_notes(repo)
    end
  end

  defp assert_notes_table_is_present(repo) do
    assert find_tenant_notes(repo) == []
  end

  defp create_and_migrate_tenant(repo) do
    Triplex.create(@tenant, repo)
  end

  defp create_tenant_schema(repo) do
    Triplex.create_schema(@tenant, repo)
  end

  defp find_tenant_notes(repo) do
    query =
      Note
      |> Ecto.Queryable.to_query()
      |> Map.put(:prefix, @tenant)

    repo.all(query)
  end

  defp force_migration_failure(repo, migration_function) do
    sql =
      case repo.__adapter__ do
        Ecto.Adapters.MyXQL ->
          """
          DELETE FROM #{@tenant}.schema_migrations
          """

        _ ->
          """
          DELETE FROM "#{@tenant}"."schema_migrations"
          """
      end

    {:ok, _} = Ecto.Adapters.SQL.query(repo, sql, [])

    if repo.__adapter__ == Ecto.Adapters.MyXQL do
      migration_function.("(1050) (ER_TABLE_EXISTS_ERROR) Table 'notes' already exists")
    else
      migration_function.("ERROR 42P07 (duplicate_table) relation \"notes\" already exists")
    end
  end
end
