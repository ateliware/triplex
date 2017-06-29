defmodule Mix.Triplex do
  @moduledoc """
  Useful functions for any triplex mix task.
  """

  def ensure_tenant_migrations_path(repo) do
    with false <- Mix.Project.umbrella?,
         path = Path.relative_to(Triplex.migrations_path(repo),
                                 Mix.Project.app_path),
         false <- File.dir?(path),
         do: Mix.raise """
         Could not find tenant migrations directory #{inspect path} for
         repo #{inspect repo}
         """
    repo
  end
end
