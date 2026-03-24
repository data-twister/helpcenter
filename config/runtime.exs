import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/framework start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :framework, FrameworkWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :framework, Framework.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  origin = {FrameworkWeb.Origin, :verify_origin?, []}

  config :framework, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :framework, FrameworkWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    check_origin: origin,
    secret_key_base: secret_key_base

  config :framework,
    token_signing_secret:
      System.get_env("TOKEN_SIGNING_SECRET") ||
        raise("Missing environment variable `TOKEN_SIGNING_SECRET`!")

  # S3 / Waffle (product photo uploads)
  if System.get_env("AWS_ACCESS_KEY_ID") do
    config :ex_aws,
      json_codec: Jason,
      access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
      secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
      region: System.get_env("AWS_REGION") || "us-east-1",
      s3: [
        scheme: System.get_env("AWS_S3_SCHEME") || "https://",
        host: System.get_env("AWS_S3_HOST") || "s3.amazonaws.com",
        region: System.get_env("AWS_REGION") || "us-east-1"
      ]

    config :waffle,
      storage: Waffle.Storage.S3,
      bucket: System.get_env("AWS_S3_BUCKET"),
      asset_host: System.get_env("AWS_ASSET_HOST")
  end

  config :sentry,
    dsn: System.get_env("SENTRY_DSN") || nil

  email_provider = System.get_env("EMAIL_PROVIDER")

  cond do
    email_provider in ~w(sendgrid postmark brevo) ->
      adapter =
        case email_provider do
          "sendgrid" -> Swoosh.Adapters.SendGrid
          "postmark" -> Swoosh.Adapters.Postmark
          "brevo" -> Swoosh.Adapters.Brevo
        end

      config :framework, Framework.Mailer,
        adapter: adapter,
        api_key: System.get_env("EMAIL_API_KEY")

      config :swoosh, :api_client, Finch
      config :swoosh, :finch_name, Framework.Finch

    email_provider == "mailgun" ->
      config :craftplan, Framework.Mailer,
        adapter: Swoosh.Adapters.Mailgun,
        api_key: System.get_env("EMAIL_API_KEY"),
        domain: System.get_env("EMAIL_API_DOMAIN")

      config :swoosh, :api_client, Finch
      config :swoosh, :finch_name, Framework.Finch

    email_provider == "amazon_ses" ->
      config :craftplan, Framework.Mailer,
        adapter: Swoosh.Adapters.AmazonSES,
        access_key: System.get_env("EMAIL_API_KEY"),
        secret: System.get_env("EMAIL_API_SECRET"),
        region: System.get_env("EMAIL_API_REGION") || "us-east-1"

      config :swoosh, :api_client, Finch
      config :swoosh, :finch_name, Framework.Finch

    System.get_env("SMTP_HOST") != nil ->
      config :craftplan, Framework.Mailer,
        adapter: Swoosh.Adapters.SMTP,
        relay: System.get_env("SMTP_HOST"),
        port: String.to_integer(System.get_env("SMTP_PORT") || "587"),
        username: System.get_env("SMTP_USERNAME"),
        password: System.get_env("SMTP_PASSWORD"),
        tls: :always,
        auth: :always

      config :swoosh, :api_client, Finch
      config :swoosh, :finch_name, Framework.Finch

    true ->
      # No email provider configured — use Logger adapter so emails are
      # logged instead of crashing (Local adapter's memory store is
      # disabled in prod).
      config :craftplan, Framework.Mailer, adapter: Swoosh.Adapters.Logger
  end
end
