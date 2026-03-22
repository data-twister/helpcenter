defmodule Framework.Accounts.Tenant.Changes.AssociateUserToTenant do
  @moduledoc """
  Link user to the tenant via user_tenants relationship so that when
  we are listing owners tenants, this tenant will be listed as well
  """

  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, &associate_owner_to_tenant/2)
  end

  defp associate_owner_to_tenant(_changeset, tenant) do
    params = %{user_id: tenant.owner_user_id, tenant_id: tenant.id}

    {:ok, _user_tenant} =
      Framework.Accounts.UserTenant
      |> Ash.Changeset.for_create(:create, params)
      |> Ash.create()

    {:ok, tenant}
  end
end
