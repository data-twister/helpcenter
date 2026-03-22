defmodule Framework.Accounts.User.Changes.CreatePersonalTenant do
  use Ash.Resource.Change

  def change(%Ash.Changeset{action_type: :create} = changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, &create_personal_tenant/2)
  end

  def change(changeset, _opts, _context), do: changeset

  def atomic(changeset, _opts, _context), do: {:ok, changeset}

  defp create_personal_tenant(_changeset, user) do
    tenant_count = Ash.count!(Framework.Accounts.Tenant) + 1

    tenant_attrs = %{
      name: "Personal Tenant",
      domain: "personal_tenant_#{tenant_count}",
      owner_user_id: user.id
    }

    Ash.create(Framework.Accounts.Tenant, tenant_attrs)
  end
end
