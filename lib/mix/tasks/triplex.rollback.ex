defmodule Mix.Tasks.Triplex.Rollback do
  use Mix.Task
  import Mix.Ecto
  import Mix.EctoSQL
  import Mix.Triplex

  @shortdoc "Rolls back the repository tenant migrations"

  @aliases [
    r: :repo,
    n: :step
  ]

  @switches [
    all: :boolean,
    step: :integer,
    to: :integer,
    start: :boolean,
    quiet: :boolean,
    prefix: :string,
    pool_size: :integer,
    log_sql: :boolean,
    repo: [:keep, :string],
    no_compile: :boolean,
    no_deps_check: :boolean
  ]

  @moduledoc """
  Reverts applied migrations in the given repository.

  Tenant migrations are expected at "priv/YOUR_REPO/tenant_migrations" directory
  of the current application, where "YOUR_REPO" is the last segment
  in your repository name. For example, the repository `MyApp.Repo`
  will use "priv/repo/tenant_migrations". The repository `Whatever.MyRepo`
  will use "priv/my_repo/tenant_migrations".

  You can configure a repository to use another directory by specifying
  the `:priv` key under the repository configuration. The "migrations"
  part will be automatically appended to it. For instance, to use
  "priv/custom_repo/migrations":

      config :my_app, MyApp.Repo, priv: "priv/custom_repo"

  This task runs all pending migrations by default. Runs the last
  applied migration by default. To roll back to a version number,
  supply `--to version_number`. To roll back a specific number of
  times, use `--step n`. To undo all applied migrations, provide
  `--all`.

  The repositories to rollback are the ones specified under the
  `:ecto_repos` option in the current app configuration. However,
  if the `-r` option is given, it replaces the `:ecto_repos` config.

  If a repository has not yet been started, one will be started outside
  your application supervision tree and shutdown afterwards.

  ## Examples

      mix ecto.rollback
      mix ecto.rollback -r Custom.Repo

      mix ecto.rollback -n 3
      mix ecto.rollback --step 3

      mix ecto.rollback --to 20080906120000

  ## Command line options

    * `-r`, `--repo` - the repo to rollback
    * `--all` - revert all applied migrations
    * `--step` / `-n` - revert n number of applied migrations
    * `--to` - revert all migrations down to and including version
    * `--quiet` - do not log migration commands
    * `--pool-size` - the pool size if the repository is started only for the task (defaults to 1)
    * `--log-sql` - log the raw sql migrations are running
    * `--no-compile` - does not compile applications before rolling back
    * `--no-deps-check` - does not check depedendencies before rolling back

  ## PS

  All of this code is copied from `mix ecto.rollback` task, if something does
  not work, please compare them and try to stay as close to it as possible.
  """

  @impl true
  def run(args, migrator \\ &Ecto.Migrator.run/4) do
    repos = parse_repo(args)
    {opts, _} = OptionParser.parse! args, strict: @switches, aliases: @aliases

    opts =
      if opts[:to] || opts[:step] || opts[:all],
        do: opts,
        else: Keyword.put(opts, :step, 1)

    opts =
      if opts[:quiet],
        do: Keyword.merge(opts, [log: false, log_sql: false]),
        else: opts

    Enum.each repos, fn repo ->
      ensure_repo(repo, args)
      path = ensure_tenant_migrations_path(repo)
      {:ok, pid, apps} = ensure_started(repo, opts)

      pool = repo.config[:pool]
      Code.compiler_options(ignore_module_conflict: true)

      migrated =
        repo
        |> Triplex.all()
        |> Enum.flat_map(&run_migrator(&1, pool, migrator, repo, path, :down, opts))

      Code.compiler_options(ignore_module_conflict: false)

      pid && repo.stop()
      restart_apps_if_migrated(apps, migrated)
    end
  end
end
