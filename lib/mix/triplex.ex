defmodule Mix.Triplex do
  @moduledoc """
  Useful functions for any triplex mix task.
  """

  alias Mix.Project

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
