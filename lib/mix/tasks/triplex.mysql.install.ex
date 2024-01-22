defmodule Mix.Tasks.Triplex.Mysql.Install do
  @moduledoc """
  Generates a migration to create the tenant table
  in the default database (MySQL only).
  """

  use Mix.Task

  require Mix.Generator

  alias Ecto.Adapters.MyXQL
  alias Ecto.Migrator
  alias Mix.Ecto
  alias Mix.Generator
  alias Mix.Project

  @migration_name "create_tenant"

  @shortdoc "Generates a migration for the tenant table in the default database"

  @doc false
  def run(args) do
    Ecto.no_umbrella!("ecto.gen.migration")
    repos = Ecto.parse_repo(args)

    Enum.each(repos, fn repo ->
      Ecto.ensure_repo(repo, args)

      if repo.__adapter__ != MyXQL do
        Mix.raise("the tenant table only makes sense for MySQL repositories")
      end

      path = Path.relative_to(Migrator.migrations_path(repo), Project.app_path())
      file = Path.join(path, "#{Mix.Triplex.timestamp()}_#{@migration_name}.exs")
      Generator.create_directory(path)

      Generator.create_file(
        file,
        migration_template(
          repo: repo,
          migration_name: @migration_name,
          tenant_table: Triplex.config().tenant_table
        )
      )
    end)
  end

  defp pad(i), do: i |> to_string() |> String.pad_leading(2, "0")

  Generator.embed_template(:migration, """
  defmodule <%= Module.concat([@repo, Migrations, Macro.camelize(@migration_name)]) %> do
    use Ecto.Migration

    def change do
      create table(:<%= @tenant_table %>) do
        add :name, :string
      end
      create unique_index(:<%= @tenant_table %>, [:name])
    end
  end
  """)
end
