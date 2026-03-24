defmodule Framework.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FrameworkWeb.Telemetry,
      Framework.Repo,
      {DNSCluster, query: Application.get_env(:framework, :dns_cluster_query) || :ignore},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:framework, :ash_domains),
         Application.fetch_env!(:framework, Oban)
       )},
      {Phoenix.PubSub, name: Framework.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Framework.Finch},
      # Start a worker by calling: Framework.Worker.start_link(arg)
      # {Framework.Worker, arg},
      # Start to serve requests, typically the last entry
      FrameworkWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :framework]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Framework.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FrameworkWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @app Mix.Project.config()[:app]
  @version Mix.Project.config()[:version]
  @description Mix.Project.config()[:description]
  @build_date Mix.Project.config()[:build_date]
  @build_hash Mix.Project.config()[:build_hash]

  def build_hash, do: [build_hash: @build_hash]
  def build_date, do: [build_date: @build_date]
  def description, do: [description: @description]
  def version, do: [version: @version]
  def name, do: [app: @app]
end
