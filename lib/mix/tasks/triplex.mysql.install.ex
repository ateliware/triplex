defmodule Mix.Tasks.Triplex.Mysql.Install do
  use Mix.Task

  import Macro, only: [camelize: 1]
  import Mix.Generator
  import Mix.Ecto

  alias Mix.Project
  alias Ecto.Migrator

  @migration_name "create_tenant"

  @shortdoc "Generates a migration for the tenant table in the default database"

  @moduledoc """
  Generates a migration to create the tenant table
  in the default database (MySQL only).
  """

  @doc false
  def run(args) do
    no_umbrella!("ecto.gen.migration")
    repos = parse_repo(args)

    Enum.each repos, fn repo ->
      ensure_repo(repo, args)
      if repo.__adapter__ != Ecto.Adapters.MySQL do
        Mix.raise "the tenant table only makes sense for MySQL repositories"
      end

      path = Path.relative_to(Migrator.migrations_path(repo), Project.app_path())
      file = Path.join(path, "#{timestamp()}_#{@migration_name}.exs")
      create_directory path

      create_file file, migration_template(repo: repo, migration_name: @migration_name, tenant_table: Triplex.config().tenant_table)
    end
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i), do: i |> to_string() |> String.pad_leading(2, "0")

  embed_template :migration, """
  defmodule <%= Module.concat([@repo, Migrations, camelize(@migration_name)]) %> do
    use Ecto.Migration

    def change do
      create table(:<%= @tenant_table %>) do
        add :name, :string
      end
      create unique_index(:<%= @tenant_table %>, [:name])
    end
  end
  """
end
