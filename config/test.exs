use Mix.Config

# Configure triplex
# TODO - I had to rip it off from here, because of umbrella project
# configuration, check if is there a way not to conflict these configurations,
# once this becomes a external lib, we can put this code back
# config :triplex,
#   reserved_tenants: [
#     "www", "api", "admin", "security", "app", "staging", ~r/^db\d+$/
#   ]

# Configure your database
config :triplex, ecto_repos: [Triplex.TestRepo]
config :triplex, Triplex.TestRepo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("PG_USERNAME") || "postgres",
  password: System.get_env("PG_PASSWORD") || "postgres",
  hostname: System.get_env("PG_HOST") || "localhost",
  database: "triplex_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn
