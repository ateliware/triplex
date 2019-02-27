defmodule Mix.Tasks.Triplex.Gen.MigrationTest do
  use ExUnit.Case, async: true

  import Support.FileHelpers
  alias Mix.Tasks.Triplex.Gen.Migration

  tmp_path = Path.join(tmp_path(), inspect(Migration))
  @migrations_path Path.join(tmp_path, Triplex.config().migrations_path)

  defmodule Repo do
    def __adapter__ do
      true
    end

    def config do
      [priv: "tmp/#{inspect(Migration)}", otp_app: :triplex]
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

  test "generates a new migration" do
    Migration.run(["-r", to_string(Repo), "test"])
    assert [name] = File.ls!(@migrations_path)
    assert String.match?(name, ~r/^\d{14}_test\.exs$/)

    assert_file(Path.join(@migrations_path, name), fn file ->
      assert file =~ """
             defmodule Mix.Tasks.Triplex.Gen.MigrationTest.Repo.Migrations.Test do
             """

      assert file =~ "use Ecto.Migration"
      assert file =~ "def change do"
    end)
  end

  test "underscores the filename when generating a migration" do
    Migration.run(["-r", to_string(Repo), "MyMigration"])
    assert [name] = File.ls!(@migrations_path)
    assert String.match?(name, ~r/^\d{14}_my_migration\.exs$/)
  end

  test "raises when missing file" do
    assert_raise Mix.Error, fn -> Migration.run(["-r", to_string(Repo)]) end
  end
end
