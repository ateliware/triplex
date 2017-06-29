defmodule Mix.TriplexTest do
  use ExUnit.Case, async: true
  import Mix.Triplex

  defmodule LostRepo do
    def config do
      [priv: "where", otp_app: :triplex]
    end
  end

  test "ensure tenant migrations path" do
    msg = """
    Could not find tenant migrations directory \"where/tenant_migrations\" for
    repo Mix.TriplexTest.LostRepo
    """
    assert_raise Mix.Error, msg, fn ->
      ensure_tenant_migrations_path(LostRepo)
    end
  end
end
