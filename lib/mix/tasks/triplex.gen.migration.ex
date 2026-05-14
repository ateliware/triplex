defmodule Mix.Tasks.Triplex.Gen.Migration do
  use Mix.Task

  require Mix.Generator

  alias Mix.Generator
  alias Mix.Project

  @shortdoc "Generates a new tenant migration for the repo"

  @moduledoc """
  Generates a migration.

  The repository must be set under `:ecto_repos` in the
  current app configuration or given via the `-r` option.

  ## Examples

      mix triplex.gen.migration add_posts_table
      mix triplex.gen.migration add_posts_table -r Custom.Repo

  By default, the migration will be generated to the
  "priv/YOUR_REPO/migrations" directory of the current application
  but it can be configured to be any subdirectory of `priv` by
  specifying the `:priv` key under the repository configuration.

  This generator will automatically open the generated file if
  you have `ECTO_EDITOR` set in your environment variable.

  ## Command line options

    * `-r`, `--repo` - the repo to generate migration for

  ## PS

  All of this code is copied from `mix ecto.gen.migration` task, if something
  does not work, please compare them and try to stay as close to it as possible.
  """

  alias Mix.Ecto

  @switches [change: :string]

  @doc false
  def run(args) do
    Ecto.no_umbrella!("ecto.gen.migration")
    repos = Ecto.parse_repo(args)

    Enum.each(repos, fn repo ->
      case OptionParser.parse(args, switches: @switches) do
        {opts, [name], _} ->
          Ecto.ensure_repo(repo, args)

          path =
            repo
            |> Triplex.migrations_path()
            |> Path.relative_to(Project.app_path())

          file = Path.join(path, "#{Mix.Triplex.timestamp()}_#{Macro.underscore(name)}.exs")
          Generator.create_directory(path)

          assigns = [
            mod: Module.concat([repo, Migrations, Macro.camelize(name)]),
            change: opts[:change]
          ]

          Generator.create_file(file, migration_template(assigns))

        {_, _, _} ->
          Mix.raise(
            "expected ecto.gen.migration to receive the migration " <>
              "file name, got: #{inspect(Enum.join(args, " "))}"
          )
      end
    end)
  end

  Generator.embed_template(:migration, """
  defmodule <%= inspect @mod %> do
    use Ecto.Migration

    def change do
  <%= @change %>
    end
  end
  """)
end
