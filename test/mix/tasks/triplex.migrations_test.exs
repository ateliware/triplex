defmodule Mix.Tasks.Triplex.MigrationsTest do
  use ExUnit.Case

  alias Mix.Tasks.Triplex.Migrations
  alias Ecto.Migrator

  @repos [Triplex.PGTestRepo, Triplex.MSTestRepo]

  setup do
    for repo <- @repos do
      Ecto.Adapters.SQL.Sandbox.mode(repo, :auto)

      drop_tenants = fn ->
        Triplex.drop("migrations_test_down", repo)
        Triplex.drop("migrations_test_up", repo)
      end

      drop_tenants.()
      on_exit(drop_tenants)
    end

    :ok
  end

  test "runs migration for each tenant, with the correct prefix" do
    for repo <- @repos do
      Triplex.create_schema("migrations_test_down", repo)
      Triplex.create("migrations_test_up", repo)

      Migrations.run(["-r", repo], &Migrator.migrations/2, fn msg ->
        assert msg =~
                 """
                 Repo: #{inspect(repo)}
                 Tenant: migrations_test_down

                   Status    Migration ID    Migration Name
                 --------------------------------------------------
                   down      20160711125401  test_create_tenant_notes
                 """

        assert msg =~
                 """
                 Repo: #{inspect(repo)}
                 Tenant: migrations_test_up

                   Status    Migration ID    Migration Name
                 --------------------------------------------------
                   up        20160711125401  test_create_tenant_notes
                 """
      end)
    end
  end
end
