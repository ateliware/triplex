defmodule Mix.Tasks.Triplex.RollbackTest do
  use ExUnit.Case

  alias Mix.Tasks.Triplex.Rollback

  @repos [Triplex.PGTestRepo, Triplex.MySQLTestRepo]

  test "runs the migrator function" do
    for repo <- @repos do
      Rollback.run(["-r", repo, "--step=1", "--quiet"], fn args, direction ->
        assert args == ["-r", repo, "--step=1", "--quiet"]
        assert direction == :down
      end)
    end
  end
end
