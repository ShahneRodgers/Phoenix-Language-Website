use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :language, LanguageWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only errors during test
config :logger, level: :error

# Don't waste time with authentication when running tests
config :bcrypt_elixir, :log_rounds, 4

# Configure your database
config :language, Language.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "language_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :language, :environment, :test
