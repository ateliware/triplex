defmodule Elixir.Triplex.MSTestRepo.Migrations.CreateTenant do
  use Ecto.Migration

  def change do
    create table(:tenants) do
      add :name, :string
    end
    create unique_index(:tenants, [:name])
  end
end
