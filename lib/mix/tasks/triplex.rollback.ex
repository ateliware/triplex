defmodule Mix.Tasks.Triplex.Rollback do
  use Mix.Task

  @shortdoc "Rolls back the repository tenant migrations"

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

  To change the "tenant_migrations" part, you can set the `:migrations_path`
  config under triplex configuration. For example, to use "priv/repo/my_migrations":

      config :triplex, migrations_path: "my_migrations"

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
    * `--no-deps-check` - does not check dependencies before rolling back

  ## PS

  All of this code is copied from `mix ecto.rollback` task, if something does
  not work, please compare them and try to stay as close to it as possible.
  """

  alias Mix.Triplex

  @impl true
  def run(args, migrator \\ &Triplex.run_tenant_migrations/2) do
    migrator.(args, :down)
  end
end
