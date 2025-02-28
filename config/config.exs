# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :case_manager, CaseManager.Mailer, adapter: Swoosh.Adapters.Local

# Configures the endpoint
config :case_manager, CaseManagerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: CaseManagerWeb.ErrorHTML, json: CaseManagerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: CaseManager.PubSub,
  live_view: [signing_salt: "h2rjo2el"]

config :case_manager,
  ecto_repos: [CaseManager.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  case_manager: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :mime,
  extensions: %{"json" => "application/vnd.api+json"},
  types: %{"application/vnd.api+json" => ["json"]}

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :spark,
  formatter: [
    "Ash.Resource": [section_order: [:json_api]],
    "Ash.Domain": [section_order: [:json_api]]
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  case_manager: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),

    # Import environment specific config. This must remain at the bottom
    # of this file so it overrides the configuration defined above.
    cd: Path.expand("../assets", __DIR__)
  ]

import_config "#{config_env()}.exs"

config :ash, :policies, no_filter_static_forbidden_reads?: false
config :ash, :pub_sub, debug?: true

config :ash,
  include_embedded_source_by_default?: false,
  default_page_type: :keyset

config :case_manager, :ash_domains, [
  CaseManager.Configuration,
  CaseManager.ICM,
  CaseManager.Teams
]

config :case_manager, :token_signing_secret, "some_super_secret_random_value"
