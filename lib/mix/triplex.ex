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

  alias Mix.Project

  @doc """
  Ensures the migrations path exists for the given repo.

  Raises a `Mix.raise` if it fails and returns the repo if succeed.
  """
  def ensure_tenant_migrations_path(repo, config \\ Project.config()) do
    with false <- Project.umbrella?(config),
         path = relative_migrations_path(repo, config),
         false <- File.dir?(path) do
      Mix.raise """
      Could not find tenant migrations directory #{inspect path} for
      repo #{inspect repo}
      """
    end

    repo
  end

  defp relative_migrations_path(repo, config) do
    repo
    |> Triplex.migrations_path()
    |> Path.relative_to(Project.app_path(config))
  end
end
