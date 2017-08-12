defmodule Mix.Tasks.Triplex.MigrationsTest do
  use ExUnit.Case
  import Mix.Tasks.Triplex.Migrations, only: [run: 3]
  alias Ecto.Migrator

  @repo Triplex.TestRepo

  setup do
    Ecto.Adapters.SQL.Sandbox.mode(@repo, :manual)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(@repo)
  end

  test "runs migration for each tenant, with the correct prefix" do
    Triplex.create_schema("migrations_test", @repo)

    run(["-r", @repo], &Migrator.migrations/2, fn(msg) ->
      assert msg ==
        """

        Repo: Triplex.TestRepo

          Status    Migration ID    Migration Name
        --------------------------------------------------
          down      20160711125401  test_create_tenant_notes
        """
    end)
  end
end

