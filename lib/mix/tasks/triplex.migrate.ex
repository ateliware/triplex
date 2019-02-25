defmodule Mix.Tasks.Triplex.Migrate do
  use Mix.Task

  @shortdoc "Runs the repository tenant migrations"

  @moduledoc """
  Runs the pending tenant migrations for the given repository.

  Tenant migrations are expected at "priv/YOUR_REPO/tenant_migrations" directory
  of the current application, where "YOUR_REPO" is the last segment
  in your repository name. For example, the repository `MyApp.Repo`
  will use "priv/repo/tenant_migrations". The repository `Whatever.MyRepo`
  will use "priv/my_repo/tenant_migrations".

  You can configure a repository to use another directory by specifying
  the `:priv` key under the repository configuration. The "tenant_migrations"
  part will be automatically appended to it. For instance, to use
  "priv/custom_repo/tenant_migrations":

      config :my_app, MyApp.Repo, priv: "priv/custom_repo"

  To change the "tenant_migrations" part, you can set the `:migrations_path`
  config under triplex configuration. For example, to use "priv/repo/my_migrations":

      config :triplex, migrations_path: "my_migrations"

  This task runs all pending tenant migrations by default. To migrate up to a
  specific version number, supply `--to version_number`. To migrate a
  specific number of times, use `--step n`.

  The repositories to migrate are the ones specified under the
  `:ecto_repos` option in the current app configuration. However,
  if the `-r` option is given, it replaces the `:ecto_repos` config.

  Since Ecto tasks can only be executed once, if you need to migrate
  multiple repositories, set `:ecto_repos` accordingly or pass the `-r`
  flag multiple times.

  If a repository has not yet been started, one will be started outside
  your application supervision tree and shutdown afterwards.

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
    * `--to` - run all migrations up to and including version
    * `--quiet` - do not log migration commands
    * `--pool-size` - the pool size if the repository is started only for the task (defaults to 1)
    * `--log-sql` - log the raw sql migrations are running
    * `--strict-version-order` - abort when applying a migration with old timestamp
    * `--no-compile` - does not compile applications before migrating
    * `--no-deps-check` - does not check depedendencies before migrating

  ## PS

  All of this code is copied from `mix ecto.migrate` task, if something does
  not work, please compare them and try to stay as close to it as possible.
  """

  @impl true
  def run(args, migrator \\ &Mix.Triplex.run_tenant_migrations/2) do
    migrator.(args, :up)
  end
end
