defmodule Triplex.PGTestRepo do
  use Ecto.Repo, otp_app: :triplex, adapter: Ecto.Adapters.Postgres
end
