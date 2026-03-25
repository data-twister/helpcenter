# lib/framework_web/live/tenant_on_mount.ex
defmodule FrameworkWeb.TenantOnMount do
  import Phoenix.LiveView
  use FrameworkWeb, :live_view

  def on_mount(:default, _params, _session, socket) do
    host = socket.assigns[:host]

    tenant =
      case Tenants.resolve(host) do
        {:ok, t} -> t
        _ -> nil
      end

    {:cont, assign(socket, :tenant, tenant)}
  end
end
