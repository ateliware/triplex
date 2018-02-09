defmodule Mix.Tasks.Triplex.RollbackTest do
  use ExUnit.Case
  import Mix.Tasks.Triplex.Rollback, only: [run: 3]

  @repo Triplex.TestRepo

  setup do
    if @repo.__adapter__ == Ecto.Adapters.MySQL do
      Ecto.Adapters.SQL.Sandbox.mode(@repo, :auto)
      drop_tenants = fn -> 
        Triplex.drop("rollback_test1", @repo)
        Triplex.drop("rollback_test2", @repo)
      end
      drop_tenants.()
      on_exit drop_tenants
      :ok
    else 
      Ecto.Adapters.SQL.Sandbox.mode(@repo, :manual)
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(@repo)
    end
  end

  test "runs migration rollback for each tenant, with the correct prefix" do
    Triplex.create("rollback_test1", @repo)
    Triplex.create("rollback_test2", @repo)

    run(["-r", @repo, "--step=1", "--quiet"], fn(@repo, path, :down, opts) ->
      assert path == Mix.Triplex.migrations_path(@repo)
      assert opts[:step] == 1
      assert opts[:log] == false

      send self(), {:ok, opts[:prefix]}
    end, true)
    assert_received {:ok, "rollback_test1"}
    assert_received {:ok, "rollback_test2"}

    run(["-r", @repo], fn(_, _, _, _) ->
      send self(), :error
    end, false)
    refute_received :error
  end
end
