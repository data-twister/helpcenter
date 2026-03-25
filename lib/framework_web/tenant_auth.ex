# lib/framework_web/live/tenant_on_mount.ex
defmodule FrameworkWeb.TenantOnMount do
  import Phoenix.LiveView
  alias Framework.Accounts.Tenant

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
