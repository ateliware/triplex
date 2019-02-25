defmodule Mix.TriplexTest do
  use ExUnit.Case, async: true

  import Mix.Triplex
  alias Triplex.TestRepo

  @repo TestRepo

  defmodule LostRepo do
    def config do
      [priv: "where", otp_app: :triplex]
    end
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
end
