defmodule FrameworkWeb.Plugs.SetTenant do
  import Plug.Conn
  alias Framework.Accounts.Tenant

  def init(opts), do: opts

  def call(conn, _opts) do
    domain = conn.host

    tenant =
      case Tenant.by_domain(domain) do
        {:ok, t} -> t
        _ -> nil
      end

    if tenant, do: Ash.set_tenant(tenant)

    assign(conn, :tenant, tenant)
  end
end
