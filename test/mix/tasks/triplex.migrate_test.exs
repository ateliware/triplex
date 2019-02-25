defmodule Mix.Tasks.Triplex.MigrateTest do
  use ExUnit.Case
  import Mix.Tasks.Triplex.Migrate, only: [run: 2]

  @repo Triplex.TestRepo
  @args ["-r", @repo, "--step=1", "--quiet"]

  test "runs the migrator function" do
    run(@args, fn(args, direction) ->
      assert @args == args
      assert direction == :up
    end)
  end
end

