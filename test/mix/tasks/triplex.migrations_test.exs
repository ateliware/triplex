defmodule Mix.Tasks.Triplex.MigrationsTest do
  use ExUnit.Case

  alias Mix.Tasks.Triplex.Migrations
  alias Ecto.Migrator

  import Triplex.TestHelper

  def drop_tenants(_ \\ nil) do
    for repo <- repos() do
      Triplex.all(repo)
      Triplex.drop("migrations_test_down", repo)
      Triplex.drop("migrations_test_up", repo)
    end
  end

  setup_all :setup_repos

  setup do
    drop_tenants()

    on_exit(fn ->
      #  Migrations.run *STOPS* the repository! Makes sense run as a task, but not in tests
      setup_repos(nil)
      drop_tenants()
    end)
  end

  test "runs migration for each tenant, with the correct prefix" do
    #     drop_tenants()

    for repo <- repos() do
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
