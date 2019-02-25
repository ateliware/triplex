defmodule Mix.TriplexTest do
  use ExUnit.Case, async: true

  import Mix.Triplex
  alias Triplex.TestRepo

  @repo TestRepo
  @args ["-r", @repo, "--step=1", "--quiet"]

  defmodule LostRepo do
    def config do
      [priv: "where", otp_app: :triplex]
    end
  end

  setup do
    Ecto.Adapters.SQL.Sandbox.mode(@repo, :auto)
    drop_tenants = fn ->
      Triplex.drop("test1", @repo)
      Triplex.drop("test2", @repo)
    end
    drop_tenants.()
    on_exit drop_tenants
    :ok
  end

  test "ensure tenant migrations path" do
    msg = """
    Could not find migrations directory "where/tenant_migrations"
    for repo Mix.TriplexTest.LostRepo.

    This may be because you are in a new project and the
    migration directory has not been created yet. Creating an
    empty directory at the path above will fix this error.

    If you expected existing migrations to be found, please
    make sure your repository has been properly configured
    and the configured path exists.
    """
    assert_raise Mix.Error, msg, fn ->
      ensure_tenant_migrations_path(LostRepo)
    end

    assert ensure_tenant_migrations_path(TestRepo) ==
      Path.expand("priv/test_repo/tenant_migrations")
  end

  test "migrations_path/1 must return the tenant migrations path" do
    assert Mix.Triplex.migrations_path() == ""
    assert Mix.Triplex.migrations_path(@repo) =~ ~r(priv/test_repo/tenant_migrations$)
  end

  test "runs migration for each tenant, with the correct prefix" do
    Triplex.create("test1", @repo)
    Triplex.create("test2", @repo)

    run_tenant_migrations(@args, :down, fn(@repo, path, :down, opts) ->
      assert path == Mix.Triplex.migrations_path(@repo)
      assert opts[:step] == 1
      assert opts[:log] == false

      send self(), {:ok, opts[:prefix]}

      []
    end)
    assert_received {:ok, "test1"}
    assert_received {:ok, "test2"}
  end

  test "does not run if there are no tenants" do
    run_tenant_migrations(@args, :down, fn(_, _, _, _) ->
      send self(), :error

      []
    end)
    refute_received :error
  end
end
