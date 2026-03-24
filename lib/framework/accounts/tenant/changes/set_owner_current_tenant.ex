defmodule Framework.Accounts.Tenant.Changes.SetOwnerCurrentTenant do
  use Ash.Resource.Change

  def change(changeset, _tenant, _context) do
    Ash.Changeset.after_action(changeset, &set_owner_current_tenant/2)
  end

  defp set_owner_current_tenant(_changeset, tenant) do
    opts = [authorize?: false]

    {:ok, _user} =
      Framework.Accounts.User
      |> Ash.get!(tenant.owner_user_id, opts)
      |> Ash.Changeset.for_update(:set_current_tenant, %{tenant: tenant.prefix})
      |> Ash.update(opts)

    {:ok, tenant}
  end
end
