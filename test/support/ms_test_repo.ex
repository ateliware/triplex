defmodule Triplex.MSTestRepo do
  use Ecto.Repo, otp_app: :triplex, adapter: Ecto.Adapters.MyXQL
end
