defmodule Mix.Tasks.Triplex.MigrateTest do
  use ExUnit.Case
  import Mix.Tasks.Triplex.Migrate, only: [run: 3]

  @repo Triplex.TestRepo

  setup do
    Ecto.Adapters.SQL.Sandbox.mode(@repo, :manual)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(@repo)
  end

  test "runs migration for each tenant, with the correct prefix" do
    Triplex.create_schema("migrate_test1", @repo)
    Triplex.create_schema("migrate_test2", @repo)

    run(["-r", @repo, "--step=1", "--quiet"], fn(@repo, path, :up, opts) ->
      assert path == Mix.Triplex.migrations_path(@repo)
      assert opts[:step] == 1
      assert opts[:log] == false

      send self(), {:ok, opts[:prefix]}
    end, true)
    assert_received {:ok, "migrate_test1"}
    assert_received {:ok, "migrate_test2"}

    run(["-r", @repo], fn(_, _, _, _) ->
      send self(), :error
    end, false)
    refute_received :error
  end
end

