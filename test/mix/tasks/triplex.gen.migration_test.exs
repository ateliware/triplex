defmodule Mix.Tasks.Triplex.Gen.MigrationTest do
  use ExUnit.Case, async: true

  import Support.FileHelpers
  import Triplex, only: [config: 0]
  import Mix.Tasks.Triplex.Gen.Migration, only: [run: 1]

  tmp_path = Path.join(tmp_path(), inspect(Triplex.Gen.Migration))
  @migrations_path Path.join(tmp_path, config().migrations_path)

  defmodule Repo do
    def __adapter__ do
      true
    end

    def config do
      [priv: "tmp/#{inspect(Triplex.Gen.Migration)}", otp_app: :triplex]
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
    run(["-r", to_string(Repo), "test"])
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
    run(["-r", to_string(Repo), "MyMigration"])
    assert [name] = File.ls!(@migrations_path)
    assert String.match?(name, ~r/^\d{14}_my_migration\.exs$/)
  end

  test "raises when missing file" do
    assert_raise Mix.Error, fn -> run(["-r", to_string(Repo)]) end
  end
end
