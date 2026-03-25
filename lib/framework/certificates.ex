defmodule Framework.Certificates do
  @moduledoc """
  Manages TLS certificates per domain for SNI.

  - Fast lookup via ETS
  - Disk-backed cert storage
  - Hook for ACME provisioning
  """

  use GenServer

  @table :certificates

  ## Public API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc "Get cert for host (used by SNI)"
  def get_cert(host) when is_binary(host) do
    case :ets.lookup(@table, normalize(host)) do
      [{_, cert}] ->
        {:ok, cert}

      [] ->
        maybe_provision(host)
    end
  end

  @doc "Manually put a cert"
  def put_cert(domain, certfile, keyfile) do
    :ets.insert(@table, {normalize(domain), %{certfile: certfile, keyfile: keyfile}})
    :ok
  end

  @doc "Remove cert"
  def delete_cert(domain) do
    :ets.delete(@table, normalize(domain))
    :ok
  end

  ## GenServer

  def init(_) do
    table =
      :ets.new(@table, [
        :named_table,
        :public,
        read_concurrency: true
      ])

    load_existing_certs()

    {:ok, table}
  end

  ## Internal

  defp normalize(host) do
    host
    |> String.downcase()
    |> String.trim()
  end

  # Load certs from disk at boot
  defp load_existing_certs do
    cert_dir = cert_dir()

    if File.exists?(cert_dir) do
      cert_dir
      |> File.ls!()
      |> Enum.each(fn domain ->
        certfile = Path.join([cert_dir, domain, "fullchain.pem"])
        keyfile = Path.join([cert_dir, domain, "privkey.pem"])

        if File.exists?(certfile) and File.exists?(keyfile) do
          put_cert(domain, certfile, keyfile)
        end
      end)
    end
  end

  defp cert_dir do
    Application.get_env(:framework, __MODULE__)[:cert_dir] || "priv/certs"
  end

  # Attempt to provision cert if missing
  defp maybe_provision(host) do
    case provision_cert(host) do
      {:ok, %{certfile: cert, keyfile: key}} ->
        put_cert(host, cert, key)
        {:ok, %{certfile: cert, keyfile: key}}

      _ ->
        :error
    end
  end

  ## ACME provisioning hook (plug in your tool here)

  defp provision_cert(host) do
    # --- OPTION 1: shell out to certbot ---
    # System.cmd("certbot", [...])

    # --- OPTION 2: use an Elixir ACME lib (recommended) ---
    # e.g. site_encrypt / erlexec / lego wrapper

    # Placeholder:
    IO.puts("⚡ provisioning cert for #{host}")

    # Simulate failure by default
    {:error, :not_implemented}
  end
end
