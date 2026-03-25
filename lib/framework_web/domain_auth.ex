# lib/framework_web/live/domain_on_mount.ex
defmodule FrameworkWeb.DomainOnMount do
  import Phoenix.LiveView
  import Phoenix.Component

  # ---- CONFIG ----
  # Add your proxy IPs / CIDRs here (strings)
  @trusted_proxies [
    "127.0.0.1",
    "::1",
    # example private ranges (nginx, k8s, etc.)
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
    # add your load balancer / cloud proxy IPs here
  ]

  def on_mount(:default, _params, _session, socket) do
    {:cont, assign(socket, :domain, extract_domain(socket))}
  end

  # ---- CORE ----
  defp extract_domain(socket) do
    headers = get_connect_info(socket, :x_headers) || []
    uri = get_connect_info(socket, :uri)

    forwarded =
      headers
      |> Enum.find_value(fn
        {"x-forwarded-host", h} -> h |> String.split(",") |> List.first() |> String.trim()
        _ -> nil
      end)

    forwarded || (uri && uri.host)
  end
end
