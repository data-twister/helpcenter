defmodule FrameworkWeb.Plugs.RateLimit do
  import Plug.Conn

  # 1 minute
  @scale 60_000
  # requests per minute per tenant+ip
  @limit 100

  def init(opts), do: opts

  def call(conn, _opts) do
    tenant = conn.assigns[:tenant]
    ip = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

    key =
      case tenant do
        nil -> "global:#{ip}"
        t -> "tenant:#{t.id}:#{ip}"
      end

    case Hammer.check_rate(key, @scale, @limit) do
      {:allow, _count} ->
        conn

      {:deny, _limit} ->
        conn
        |> send_resp(429, "rate limited buddy 🚫")
        |> halt()
    end
  end
end
