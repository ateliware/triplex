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

  import Mix.Ecto, only: [source_repo_priv: 1]
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
    |> Path.join(config().migrations_path || "tenant_migrations")
  end

  @doc """
  Ensures the migrations path exists for the given `repo`.

  You can optionally give us the project `config` keyword list, the options we
  use are:

  - `apps_path` - this will be used to decide if it is an umbrella project, in
  this case it never fails, because umbrellas does not have migrations and
  that's right
  - `app_path` - and this will be used to get the full path to the migrations
  directory, which is relative to this path

  Returns the unchanged `repo` if succeed or raises a `Mix.raise` if it fails.
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
    |> migrations_path()
    |> Path.relative_to(Project.app_path(config))
  end
end
