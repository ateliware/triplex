use Mix.Config

# Configure triplex
config :triplex,
  reserved_tenants: [
    "www",
    "api",
    "admin",
    "security",
    "app",
    "staging",
    "triplex_test",
    "travis",
    ~r/^db\d+$/
  ]

config :triplex, tenant_table: :tenants

# Configure your database
config :triplex, ecto_repos: [Triplex.PGTestRepo, Triplex.MSTestRepo]

config :triplex, Triplex.PGTestRepo,
  username: System.get_env("PG_USERNAME") || "postgres",
  password: System.get_env("PG_PASSWORD") || "postgres",
  hostname: System.get_env("PG_HOST") || "localhost",
  database: "triplex_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :triplex, Triplex.MSTestRepo,
  username: System.get_env("MS_USERNAME") || "root",
  password: System.get_env("MS_PASSWORD") || "",
  hostname: System.get_env("MS_HOST") || "localhost",
  database: "triplex_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn
