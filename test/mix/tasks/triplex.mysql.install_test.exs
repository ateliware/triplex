defmodule Mix.Tasks.Triplex.Mysql.InstallTest do
  use ExUnit.Case, async: true

  import Support.FileHelpers

  alias Mix.Tasks.Triplex.Mysql.Install

  tmp_path = Path.join(tmp_path(), inspect(Install))
  @migrations_path Path.join(tmp_path, "migrations")

  defmodule MySQLRepo do
    def __adapter__ do
      Ecto.Adapters.MyXQL
    end

    def config do
      [priv: "tmp/#{inspect(Install)}", otp_app: :triplex]
    end
  end

  defmodule PGRepo do
    def __adapter__ do
      Ecto.Adapters.Postgres
    end

    def config do
      [priv: "tmp/#{inspect(Triplex.MySQL.Install)}", otp_app: :triplex]
    end
  end

  setup do
    File.rm_rf!(unquote(tmp_path))

    Mix.shell(Mix.Shell.Process)

    on_exit(fn ->
      Mix.shell(Mix.Shell.IO)
    end)

    :ok
  end

  test "generates a migration to install mysql" do
    Install.run(["-r", to_string(MySQLRepo)])
    assert [name] = File.ls!(@migrations_path)
    assert String.match?(name, ~r/^\d{14}_create_tenant\.exs$/)

    assert_file(Path.join(@migrations_path, name), fn file ->
      assert file =~ """
             defmodule Elixir.Mix.Tasks.Triplex.Mysql.InstallTest.MySQLRepo.Migrations.CreateTenant do
             """

      assert file =~ "use Ecto.Migration"
      assert file =~ "def change do"
      assert file =~ "create table(:tenants) do"
      assert file =~ "add :name, :string"
      assert file =~ "create unique_index(:tenants, [:name])"
    end)
  end

  test "raises an exception for non mysql repos" do
    msg = "the tenant table only makes sense for MySQL repositories"

    assert_raise Mix.Error, msg, fn ->
      Install.run(["-r", to_string(PGRepo)])
    end
  end
end
