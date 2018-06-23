# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :language,
  ecto_repos: [Language.Repo]

# Configures the endpoint
config :language, LanguageWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "cUGTfoj4UvjamowfRshEvSQpLA/ya78brFKihj95Nwl+KufA/5l6Hsvt1ifjMsrk",
  render_errors: [view: LanguageWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Language.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Configures the authentication options
config :language, Language.Accounts.Guardian,
  issuer: "language",
  # FIXME
  secret_key: "q6UtrjGSADXmtiRjCSn39agycN1U5x6AWc6jZa6TQ1Q1qPfM0iV0VbsjaHPVfWdB"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
