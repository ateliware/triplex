defmodule Mix.Tasks.Triplex.Migrations do
  use Mix.Task
  import Mix.EctoSQL
  import Mix.Ecto
  import Mix.Triplex

  alias EctoSQL.Migrator

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
    repos = parse_repo(args)

    result = Enum.map(repos, fn repo ->
      ensure_repo(repo, args)
      ensure_tenant_migrations_path(repo)
      {:ok, pid, _} = ensure_started(repo, all: true)

      migration_lists = migrations.(repo, Mix.Triplex.migrations_path(repo))
      tenant_state = Enum.map_join(Triplex.all(repo), fn tenant ->

        tenant_versions = Migrator.migrated_versions(repo, prefix: tenant)
        repo_status = Enum.map migration_lists, fn
          {_, ts, desc} ->
          if Enum.member? tenant_versions, ts do
            {:up, ts, desc}
          else
            {:down, ts, desc}              
          end
        end
        """

        Repo: #{inspect repo}
        Tenant: #{tenant}

          Status    Migration ID    Migration Name
        --------------------------------------------------
        #{migrations_table(repo_status)}
        """
      end)
      pid && repo.stop(pid)

      tenant_state
    end)

    puts.(Enum.join(result, "\n"))
  end

  defp migrations_table(repo_status) do
    Enum.map_join repo_status, "\n", fn({status, number, description}) ->
      status =
        case status do
          :up   -> "up  "
          :down -> "down"
        end

      "  #{status}      #{number}  #{description}"
    end
  end
end
