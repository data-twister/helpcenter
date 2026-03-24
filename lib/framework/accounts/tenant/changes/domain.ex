defmodule Framework.Accounts.Tenant.Changes.Domain do
  use Ash.Resource.Change

  def change(changeset, _tenant, _context) do
    Ash.Changeset.after_action(changeset, &run/2)
  end

  defp run(changeset, tenant) do
    opts = [authorize?: false]

    {:ok, _user} =
      Framework.Accounts.Tenant
      |> Ash.get!(tenant.id, opts)
      |> Ash.Changeset.for_update(:update, %{domain: changeset.domain})
      |> Ash.update(opts)

    {:ok, tenant}
  end
end
