defmodule Mix.Tasks.Triplex.Migrations do
  use Mix.Task

  alias Ecto.Migrator

  alias Mix.Ecto
  alias Mix.Triplex, as: MTriplex

  @shortdoc "Displays the repository migration status"
  @recursive true

  @moduledoc """
  Displays the up / down migration status for the given repository.

  The repository must be set under `:ecto_repos` in the
  current app configuration or given via the `-r` option.

  By default, migrations are expected at "priv/YOUR_REPO/migrations"
  directory of the current application but it can be configured
  by specifying the `:priv` key under the repository configuration.

  If the repository has not been started yet, one will be
  started outside our application supervision tree and shutdown
  afterwards.

  ## Examples

      mix triplex.migrations
      mix triplex.migrations -r Custom.Repo

  ## Command line options

    * `-r`, `--repo` - the repo to obtain the status for

  """

  @doc false
  def run(args, migrations \\ &Migrator.migrations/2, puts \\ &IO.puts/1) do
    repos = Ecto.parse_repo(args)

    result =
      Enum.map(repos, fn repo ->
        Ecto.ensure_repo(repo, args)
        MTriplex.ensure_tenant_migrations_path(repo)
        {:ok, _pid, _} = MTriplex.ensure_started(repo, all: true)

        migration_lists = migrations.(repo, Triplex.migrations_path(repo))
        tenants_state = tenants_state(repo, migration_lists)

        repo.stop()

        tenants_state
      end)

    puts.(Enum.join(result, "\n"))
  end

  defp tenants_state(repo, migration_lists) do
    Enum.map_join(Triplex.all(repo), fn tenant ->
      tenant_versions = Migrator.migrated_versions(repo, prefix: tenant)
      repo_status = repo_status(migration_lists, tenant_versions)

      """

      Repo: #{inspect(repo)}
      Tenant: #{tenant}

        Status    Migration ID    Migration Name
      --------------------------------------------------
      #{migrations_table(repo_status)}
      """
    end)
  end

  defp repo_status(migration_lists, tenant_versions) do
    Enum.map(migration_lists, fn
      {_, ts, desc} ->
        if Enum.member?(tenant_versions, ts) do
          {:up, ts, desc}
        else
          {:down, ts, desc}
        end
    end)
  end

  defp migrations_table(repo_status) do
    Enum.map_join(repo_status, "\n", fn {status, number, description} ->
      status =
        case status do
          :up -> "up  "
          :down -> "down"
        end

      "  #{status}      #{number}  #{description}"
    end)
  end
end
