defmodule Mix.Triplex do
  @moduledoc """
  Useful functions for any triplex mix task.

  Here is the list of tasks we have for now:

  - [`mix triplex.gen.migration`](./Mix.Tasks.Triplex.Gen.Migration.html) -
  generates a tenant migration for the repo
  - [`mix triplex.migrate`](./Mix.Tasks.Triplex.Migrate.html) -
  runs the repository tenant migrations
  - [`mix triplex.migrations`](./Mix.Tasks.Triplex.Migrations.html) -
  displays the repository migration status
  - [`mix triplex.rollback`](./Mix.Tasks.Triplex.Rollback.html) -
  rolls back the repository tenant migrations
  """

  import Mix.Ecto
  import Mix.EctoSQL
  import Triplex, only: [config: 0]

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
    strict_version_order: :boolean,
    repo: [:keep, :string],
    no_compile: :boolean,
    no_deps_check: :boolean
  ]

  @doc """
  Ensures the migrations path exists for the given `repo`.

  Returns the path for the `repo` tenant migrations folder if succeeds
  or `Mix.raise`'s if it fails.
  """
  def ensure_tenant_migrations_path(repo) do
    path = Path.join(source_repo_priv(repo), config().migrations_path)

    if not Mix.Project.umbrella?() and not File.dir?(path) do
      raise_missing_migrations(Path.relative_to_cwd(path), repo)
    end

    path
  end

  defp raise_missing_migrations(path, repo) do
    Mix.raise("""
    Could not find migrations directory #{inspect(path)}
    for repo #{inspect(repo)}.

    This may be because you are in a new project and the
    migration directory has not been created yet. Creating an
    empty directory at the path above will fix this error.

    If you expected existing migrations to be found, please
    make sure your repository has been properly configured
    and the configured path exists.
    """)
  end

  @doc """
  Runs the tenant migrations with the given `args` and using
  `migrator` function.
  """
  def run_tenant_migrations(args, direction, migrator \\ &Ecto.Migrator.run/4) do
    repos = parse_repo(args)
    {opts, _} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)

    opts =
      if opts[:to] || opts[:step] || opts[:all],
        do: opts,
        else: Keyword.put(opts, :step, 1)

    opts =
      if opts[:quiet],
        do: Keyword.merge(opts, log: false, log_sql: false),
        else: opts

    Enum.each(repos, &run_tenant_migrations(&1, args, opts, direction, migrator))
  end

  defp run_tenant_migrations(repo, args, opts, direction, migrator) do
    ensure_repo(repo, args)
    path = ensure_tenant_migrations_path(repo)
    {:ok, pid, apps} = ensure_started(repo, opts)

    pool = repo.config[:pool]
    Code.compiler_options(ignore_module_conflict: true)

    migrated =
      Enum.flat_map(Triplex.all(repo), fn tenant ->
        opts = Keyword.put(opts, :prefix, tenant)

        if function_exported?(pool, :unboxed_run, 2) do
          pool.unboxed_run(repo, fn -> migrator.(repo, path, direction, opts) end)
        else
          migrator.(repo, path, direction, opts)
        end
      end)

    Code.compiler_options(ignore_module_conflict: false)

    pid && repo.stop()
    restart_apps_if_migrated(apps, migrated)
  end
end
