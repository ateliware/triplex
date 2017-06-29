defmodule Mix.Tasks.Triplex.Migrate do
  use Mix.Task
  require Logger
  import Mix.Ecto
  import Mix.Triplex

  @shortdoc "Runs the repository tenant migrations"
  @recursive true

  @moduledoc """
  Runs the pending tenant migrations for the given repository.

  The repository must be set under `:ecto_repos` in the
  current app configuration or given via the `-r` option.

  By default, migrations are expected at "priv/YOUR_REPO/migrations"
  directory of the current application but it can be configured
  to be any subdirectory of `priv` by specifying the `:priv` key
  under the repository configuration.

  Runs all pending migrations by default. To migrate up
  to a version number, supply `--to version_number`.
  To migrate up a specific number of times, use `--step n`.

  If the repository has not been started yet, one will be
  started outside our application supervision tree and shutdown
  afterwards.

  ## Examples

      mix ecto.migrate
      mix ecto.migrate -r Custom.Repo

      mix ecto.migrate -n 3
      mix ecto.migrate --step 3

      mix ecto.migrate -v 20080906120000
      mix ecto.migrate --to 20080906120000

  ## Command line options

    * `-r`, `--repo` - the repo to migrate
    * `--all` - run all pending migrations
    * `--step` / `-n` - run n number of pending migrations
    * `--to` / `-v` - run all migrations up to and including version
    * `--quiet` - do not log migration commands
    * `--pool-size` - the pool size if the repository is started only for the
    task (defaults to 1)

  ## PS

  All of this code is copied from `mix ecto.migrate` task, if something does
  not work, please compare them and try to stay as close to it as possible.
  """

  @doc false
  def run(args, migrator \\ &Ecto.Migrator.run/4) do
    repos = parse_repo(args)

    {opts, _, _} = OptionParser.parse args,
      switches: [all: :boolean, step: :integer, to: :integer, quiet: :boolean,
                 pool_size: :integer],
      aliases: [n: :step, v: :to]

    opts =
      if opts[:to] || opts[:step] || opts[:all],
        do: opts,
        else: Keyword.put(opts, :all, true)

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
      if sandbox?(repo) do
        Ecto.Adapters.SQL.Sandbox.checkin(repo)
        Ecto.Adapters.SQL.Sandbox.checkout(repo,
                                           sandbox: false,
                                           ownership_timeout: :infinity)
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
    Logger.log :info, "===> Running migrations to \"#{tenant}\" tenant"
    opts = Keyword.put(opts, :prefix, tenant)

    [try do
       migrator.(repo, Triplex.migrations_path(repo), :up, opts)
    after
      sandbox?(repo) && Ecto.Adapters.SQL.Sandbox.checkin(repo)
    end | acc]
  end

  defp sandbox?(repo) do
    repo.config[:pool] == Ecto.Adapters.SQL.Sandbox
  end
end
