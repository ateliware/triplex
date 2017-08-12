defmodule Mix.Tasks.Triplex.Rollback do
  use Mix.Task
  require Logger
  import Mix.Ecto
  import Mix.Triplex

  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.Migrator

  @shortdoc "Rolls back the repository tenant migrations"
  @recursive true

  @moduledoc """
  Reverts applied migrations in the given repository.

  The repository must be set under `:ecto_repos` in the
  current app configuration or given via the `-r` option.

  By default, migrations are expected at "priv/YOUR_REPO/migrations"
  directory of the current application but it can be configured
  by specifying the `:priv` key under the repository configuration.

  Runs the latest applied migration by default. To roll back to
  to a version number, supply `--to version_number`.

  To roll back a specific number of times, use `--step n`.

  To undo all applied migrations, provide `--all`.

  If the repository has not been started yet, one will be
  started outside our application supervision tree and shutdown
  afterwards.

  ## Examples

      mix ecto.rollback
      mix ecto.rollback -r Custom.Repo
      mix ecto.rollback -n 3
      mix ecto.rollback --step 3
      mix ecto.rollback -v 20080906120000
      mix ecto.rollback --to 20080906120000

  ## Command line options

    * `-r`, `--repo` - the repo to rollback
    * `--all` - revert all applied migrations
    * `--step` / `-n` - revert n number of applied migrations
    * `--to` / `-v` - revert all migrations down to and including version
    * `--quiet` - do not log migration commands
    * `--pool-size` - the pool size if the repository is started only for the
    task (defaults to 1)

  ## PS

  All of this code is copied from `mix ecto.rollback` task, if something does
  not work, please compare them and try to stay as close to it as possible.
  """

  @doc false
  def run(args, migrator \\ &Migrator.run/4, testing? \\ false) do
    repos = parse_repo(args)

    {opts, _, _} = OptionParser.parse args,
      switches: [all: :boolean, step: :integer, to: :integer, start: :boolean,
                 quiet: :boolean, pool_size: :integer],
      aliases: [n: :step, v: :to]

    opts =
      if opts[:to] || opts[:step] || opts[:all],
        do: opts,
        else: Keyword.put(opts, :step, 1)

    opts =
      if opts[:quiet],
        do: Keyword.put(opts, :log, false),
        else: opts

    Enum.each repos, fn repo ->
      ensure_repo(repo, args)
      ensure_tenant_migrations_path(repo)
      {:ok, pid, apps} = ensure_started(repo, opts)

      # If the pool is Ecto.Adapters.SQL.Sandbox,
      # let's make sure we get a connection outside of a sandbox.
      if sandbox?(repo) and !testing? do
        Sandbox.checkin(repo)
        Sandbox.checkout(repo, sandbox: false, ownership_timeout: :infinity)
      end

      Code.compiler_options(ignore_module_conflict: true)
      migrated = Enum.reduce Triplex.all(repo), [], fn(tenant, acc) ->
        migrate_tenant(opts, migrator, repo, tenant, acc)
      end
      Code.compiler_options(ignore_module_conflict: false)

      pid && repo.stop(pid)
      restart_apps_if_migrated(apps, List.flatten(migrated))
    end
  end

  defp migrate_tenant(opts, migrator, repo, tenant, acc) do
    Logger.log :info, "===> Rolling back \"#{tenant}\" tenant"
    opts = Keyword.put(opts, :prefix, tenant)

    [try do
       migrator.(repo, Triplex.migrations_path(repo), :down, opts)
    after
      sandbox?(repo) && Sandbox.checkin(repo)
    end | acc]
  end

  defp sandbox?(repo) do
    repo.config[:pool] == Sandbox
  end
end
