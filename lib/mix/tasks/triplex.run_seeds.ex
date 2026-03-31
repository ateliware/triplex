defmodule Mix.Tasks.Triplex.RunSeeds do
  use Mix.Task

  @shortdoc "Runs the tenant seeds"

  @moduledoc """
  Runs the tenant seeds for the given repository.

  Tenant seeds are expected at "priv/YOUR_REPO/tenant_seeds.exs" file
  of the current application, where "YOUR_REPO" is the last segment
  in your repository name. For example, the repository `MyApp.Repo`
  will use "priv/repo/tenant_seeds.exs". The repository `Whatever.MyRepo`
  will use "priv/my_repo/tenant_seeds.exs".

  You can configure a repository to use another directory by specifying
  the `:priv` key under the repository configuration. For instance, to use
  "priv/custom_repo/tenant_seeds.exs":

      config :my_app, MyApp.Repo, priv: "priv/custom_repo"

  By default, seeds are run for **all** tenants. To run seeds for a single
  tenant only, supply `--tenant tenant_name`.

  The repositories to use are the ones specified under the `:ecto_repos`
  option in the current app configuration. However, if the `-r` option is
  given, it replaces the `:ecto_repos` config.

  If a repository has not yet been started, one will be started outside
  your application supervision tree and shutdown afterwards.

  Inside the seeds file the following bindings are available:

    * `tenant` - the tenant name (string)
    * `repo`   - the Ecto repo module

  ## Examples

      mix triplex.run_seeds
      mix triplex.run_seeds -r Custom.Repo
      mix triplex.run_seeds --tenant my_tenant
      mix triplex.run_seeds -r Custom.Repo -t my_tenant

  ## Command line options

    * `-r`, `--repo`   - the repo to use
    * `-t`, `--tenant` - run seeds for a specific tenant only
    * `--quiet`        - do not log seed progress messages
    * `--pool-size`    - the pool size if the repository is started only for
      the task (defaults to 1)
    * `--no-compile`   - does not compile applications before running seeds
    * `--no-deps-check` - does not check dependencies before running seeds
  """

  alias Mix.Triplex

  @impl true
  def run(args, runner \\ &Triplex.run_tenant_seeds/2) do
    runner.(args, &default_seed_runner/3)
  end

  defp default_seed_runner(repo, seeds_file, tenant) do
    seed_content = File.read!(seeds_file)
    Code.eval_string(seed_content, [tenant: tenant, repo: repo], file: seeds_file)
  end
end
