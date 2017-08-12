defmodule Mix.TriplexTest do
  use ExUnit.Case, async: true
  import Mix.Triplex
  alias Triplex.TestRepo

  defmodule LostRepo do
    def config do
      [priv: "where", otp_app: :triplex]
    end
  end

  test "ensure tenant migrations path" do
    msg = """
    Could not find tenant migrations directory \"#{Triplex.migrations_path(LostRepo)}\" for
    repo Mix.TriplexTest.LostRepo
    """
    assert_raise Mix.Error, msg, fn ->
      ensure_tenant_migrations_path(LostRepo)
    end

    assert ensure_tenant_migrations_path(TestRepo) == TestRepo
    assert ensure_tenant_migrations_path(LostRepo,
                                         apps_path: "apps") == LostRepo
  end
end
