# lib/framework/accounts/checks/authorized.ex
defmodule Framework.Accounts.Checks.Authorized do
  use Ash.Policy.SimpleCheck
  require Ash.Query

  @impl true
  def describe(_opts), do: "Authorize User Access Group"

  @doc """
  Returns true to authorize or false to deny access
  If actor is not provide, then deny access by returning false
  """
  @impl true

  def match?(nil = _actor, _context, _opts), do: false
  def match?(actor, context, _options), do: authorized?(actor, context)

  # """
  # 1. If the actor is the tenant owner, then authorize since he's the owner
  # 2. If none of the above, then check if the user has permission on the database
  # """
  defp authorized?(actor, context) do
    cond do
      is_current_tenant_owner?(actor) -> true
      true -> can?(actor, context)
    end
  end

  # Confirms if the actor is the owner of the current tenant
  defp is_current_tenant_owner?(actor) do
    Framework.Accounts.Tenant
    |> Ash.Query.filter(owner_user_id == ^actor.id)
    |> Ash.Query.filter(prefix == ^actor.current_tenant)
    |> Ash.exists?()
  end

  # Confirms if the actor has required permissions to perform the current
  # action on the current resource
  defp can?(actor, context) do
    Framework.Accounts.User
    |> Ash.Query.filter(id == ^actor.id)
    |> Ash.Query.load(groups: :permissions)
    |> Ash.Query.filter(groups.permissions.resource == ^context.resource)
    |> Ash.Query.filter(groups.permissions.action == ^context.subject.action.type)
    |> Ash.exists?(tenant: actor.current_tenant, authorize?: false)
  end
end
