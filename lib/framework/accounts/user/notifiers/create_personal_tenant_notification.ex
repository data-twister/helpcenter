defmodule Framework.Accounts.User.Notifiers.CreatePersonalTenantNotification do
  alias Ash.Notifier.Notification
  use Ash.Notifier

  def notify(%Notification{data: user, action: %{name: :register_with_password}}) do
    create_personal_tenant(user)
  end

  def notify(%Notification{} = _notification), do: :ok

  defp create_personal_tenant(user) do
    # Determine the count of existing tenant and use it as a
    # suffix to the tenant domain.
    tenant_count = Ash.count!(Framework.Accounts.Tenant) + 1

    tenant_attrs = %{
      name: "Personal Tenant",
      domain: "personal_tenant_#{tenant_count}",
      owner_user_id: user.id
    }

    Ash.create!(Framework.Accounts.Tenant, tenant_attrs)
  end
end
