defmodule Mix.Tasks.Triplex.MigrateTest do
  use ExUnit.Case

  alias Mix.Tasks.Triplex.Migrate

  @repos [Triplex.PGTestRepo, Triplex.MySQLTestRepo]

  test "runs the migrator function" do
    for repo <- @repos do
      Migrate.run(["-r", repo, "--step=1", "--quiet"], fn args, direction ->
        assert args == ["-r", repo, "--step=1", "--quiet"]
        assert direction == :up
      end)
    end
  end
end
