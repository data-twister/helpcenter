# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :cinder, default_theme: "modern"
config :ash_oban, pro?: false

config :framework, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [default: 10],
  repo: Framework.Repo,
  plugins: [{Oban.Plugins.Cron, []}]

config :ash,
  allow_forbidden_field_for_relationships_by_default?: true,
  include_embedded_source_by_default?: false,
  show_keysets_for_all_actions?: false,
  default_page_type: :keyset,
  policies: [no_filter_static_forbidden_reads?: false],
  known_types: [AshMoney.Types.Money],
  custom_types: [
    money: Money,
    currency: Craftplan.Types.Currency
  ]

config :spark,
  formatter: [
    remove_parens?: true,
    "Ash.Resource": [
      section_order: [
        :authentication,
        :tokens,
        :postgres,
        :resource,
        :code_interface,
        :actions,
        :policies,
        :pub_sub,
        :preparations,
        :changes,
        :validations,
        :multitenancy,
        :attributes,
        :relationships,
        :calculations,
        :aggregates,
        :identities
      ]
    ],
    "Ash.Domain": [section_order: [:resources, :policies, :authorization, :domain, :execution]]
  ]

config :framework,
  ecto_repos: [Framework.Repo],
  generators: [timestamp_type: :utc_datetime],
  ash_domains: [Framework.Accounts, Framework.KnowledgeBase]

# Configures the endpoint
config :framework, FrameworkWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: FrameworkWeb.ErrorHTML, json: FrameworkWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Framework.PubSub,
  live_view: [signing_salt: "VAJ+bMre"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :framework, Framework.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  framework: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  user: [
    args:
      ~w(js/user.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  service_worker: [
    args: ~w(js/service_worker.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  framework: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ], user: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/user.css
      --output=../priv/static/assets/user.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ex_cldr, default_backend: Framework.Cldr

config :elixir, :time_zone_database, Tz.TimeZoneDatabase

config :sentry,
       dsn: "https://examplePublicKey@o0.ingest.sentry.io/0",
       environment_name: Mix.env(),
       enable_source_code_context: true,
       root_source_code_paths: [File.cwd!()],
       integrations: [
         oban: [
           # Capture errors:
           capture_errors: true,
           # Monitor cron jobs:
           cron: [enabled: true]
         ],
         telemetry: [
           report_handler_failures: true
         ]
       ]


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
