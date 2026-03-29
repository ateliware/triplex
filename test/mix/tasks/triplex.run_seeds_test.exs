defmodule Mix.Tasks.Triplex.RunSeedsTest do
  use ExUnit.Case

  alias Mix.Tasks.Triplex.RunSeeds
  alias Triplex.Note
  alias Triplex.PGTestRepo
  alias Triplex.MSTestRepo

  @repos [PGTestRepo, MSTestRepo]
  @tenant "seeds_test_tenant"

  setup do
    for repo <- @repos do
      Ecto.Adapters.SQL.Sandbox.mode(repo, :auto)
      Triplex.drop(@tenant, repo)
      {:ok, _} = Triplex.create(@tenant, repo)
      on_exit(fn -> Triplex.drop(@tenant, repo) end)
    end

    :ok
  end

  test "seeds file is evaluated for all tenants when no --tenant given" do
    for repo <- @repos do
      seeds_file = seeds_file_path(repo)
      write_seeds(seeds_file)

      RunSeeds.run(["-r", repo, "--quiet"])

      notes = repo.all(Note, prefix: Triplex.to_prefix(@tenant))
      assert length(notes) == 1
      assert hd(notes).body == "seeded note for #{@tenant}"
    end
  end

  test "seeds file is evaluated only for specified tenant with --tenant" do
    other_tenant = "other_seeds_tenant"

    for repo <- @repos do
      Triplex.drop(other_tenant, repo)
      {:ok, _} = Triplex.create(other_tenant, repo)

      seeds_file = seeds_file_path(repo)
      write_seeds(seeds_file)

      RunSeeds.run(["-r", repo, "--tenant", @tenant, "--quiet"])

      assert length(repo.all(Note, prefix: Triplex.to_prefix(@tenant))) == 1
      assert repo.all(Note, prefix: Triplex.to_prefix(other_tenant)) == []

      Triplex.drop(other_tenant, repo)
    end
  end

  test "-t is a shorthand for --tenant" do
    for repo <- @repos do
      seeds_file = seeds_file_path(repo)
      write_seeds(seeds_file)

      RunSeeds.run(["-r", repo, "-t", @tenant, "--quiet"])

      notes = repo.all(Note, prefix: Triplex.to_prefix(@tenant))
      assert length(notes) == 1
    end
  end

  defp seeds_file_path(repo) do
    repo_folder =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    Path.join(["priv", repo_folder, "tenant_seeds.exs"])
  end

  defp write_seeds(path) do
    File.write!(path, """
    prefix = Triplex.to_prefix(tenant)
    repo.insert!(%Triplex.Note{body: "seeded note for \#{tenant}"}, prefix: prefix)
    """)
  end
end
