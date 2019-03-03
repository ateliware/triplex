defmodule Triplex.TestRepo.Migrations.CreateTenantNotes do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:notes) do
      add :body, :string
      add :parent_id, references(:notes, on_delete: :delete_all)
    end
  end
end
