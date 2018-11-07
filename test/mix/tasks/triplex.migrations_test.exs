defmodule Mix.Tasks.Triplex.MigrationsTest do
  use ExUnit.Case
  import Mix.Tasks.Triplex.Migrations, only: [run: 3]
  alias EctoSQL.Migrator

  @repo Triplex.TestRepo

  setup do
    if @repo.__adapter__ == Ecto.Adapters.MySQL do
      Ecto.Adapters.SQL.Sandbox.mode(@repo, :auto)
      drop_tenants = fn -> 
        Triplex.drop("migrations_test", @repo)
      end
      drop_tenants.()
      on_exit drop_tenants
      :ok
    else 
      Ecto.Adapters.SQL.Sandbox.mode(@repo, :manual)
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(@repo)
    end
  end

  test "runs migration for each tenant, with the correct prefix" do
    Triplex.create_schema("migrations_test", @repo)

    run(["-r", @repo], &Migrator.migrations/2, fn(msg) ->
      assert msg == Enum.map_join(Triplex.all(@repo), fn tenant ->
        """

        Repo: Triplex.TestRepo
        Tenant: #{tenant}

          Status    Migration ID    Migration Name
        --------------------------------------------------
          down      20160711125401  test_create_tenant_notes
        """
      end)
    end)
  end
end

