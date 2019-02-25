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

  import Mix.EctoSQL, only: [source_repo_priv: 1]
  import Triplex, only: [config: 0]

  @doc """
  Returns the path for your tenant migrations.
  """
  def migrations_path(repo \\ config().repo)
  def migrations_path(nil) do
    ""
  end
  def migrations_path(repo) do
    repo
    |> source_repo_priv()
    |> Path.join(config().migrations_path)
  end

  @doc """
  Ensures the migrations path exists for the given `repo`.

  Returns the path for the `repo` tenant migrations folder if succeeds
  or `Mix.raise`'s if it fails.
  """
  def ensure_tenant_migrations_path(repo) do
    path = Path.join(source_repo_priv(repo), "tenant_migrations")

    if not Mix.Project.umbrella? and not File.dir?(path) do
      raise_missing_migrations(Path.relative_to_cwd(path), repo)
    end

    path
  end

  defp raise_missing_migrations(path, repo) do
    Mix.raise """
    Could not find migrations directory #{inspect path}
    for repo #{inspect repo}.

    This may be because you are in a new project and the
    migration directory has not been created yet. Creating an
    empty directory at the path above will fix this error.

    If you expected existing migrations to be found, please
    make sure your repository has been properly configured
    and the configured path exists.
    """
  end
end
