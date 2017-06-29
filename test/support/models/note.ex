defmodule Triplex.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field :body, :string
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(body))
    |> validate_required(:body)
  end
end

