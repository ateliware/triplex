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
    Could not find tenant migrations directory \"#{Mix.Triplex.migrations_path(LostRepo)}\" for
    repo Mix.TriplexTest.LostRepo
    """
    assert_raise Mix.Error, msg, fn ->
      ensure_tenant_migrations_path(LostRepo)
    end

    assert ensure_tenant_migrations_path(TestRepo) == TestRepo
    assert ensure_tenant_migrations_path(LostRepo,
                                         apps_path: "apps") == LostRepo
  end

  test "migrations_path/1 must return the tenant migrations path" do
    expected = "priv/test_repo/tenant_migrations"
    assert Mix.Triplex.migrations_path(@repo) == expected
  end
end
