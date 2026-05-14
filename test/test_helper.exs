defmodule Triplex.TestHelper do
  def setup_repos(_) do
    for repo <- Application.get_env(:triplex, :ecto_repos) do
      repo.start_link()
      Ecto.Adapters.SQL.Sandbox.mode(repo, :auto)
    end

    :ok
  end

  def repos() do
    Application.get_env(:triplex, :ecto_repos)
  end
end

ExUnit.start()
