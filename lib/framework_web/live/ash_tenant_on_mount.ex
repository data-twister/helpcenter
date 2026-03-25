# lib/framework_web/live/ash_tenant_on_mount.ex
defmodule FrameworkWeb.AshTenantOnMount do
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    case socket.assigns[:tenant] do
      nil ->
        raise "Tenant required for authentication"

      tenant ->
        Ash.set_tenant(tenant)
        {:cont, socket}
    end
  end
end
