# lib/framework/accounts/invitation/changes/add_user_to_tenant.ex
defmodule Framework.Accounts.Invitation.Changes.AddUserToTenant do
  @moduledoc """
  An Ash Resource Change that adds a user to a tenant and permission group.

  This module handles the process of linking a user to a tenant, setting their
  current tenant, and adding them to a permission group after accepting an invitation.
  It uses Ash's seeding and querying capabilities for reliable data operations.
  """

  use Ash.Resource.Change
  require Ash.Query

  @doc """
  Registers an after_action callback to link the user to the tenant after
  the changeset is processed.
  """
  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, &link_user_to_tenant/2)
  end

  @impl true
  def atomic(changeset, opts, context) do
    {:ok, change(changeset, opts, context)}
  end

  @doc """
  Links a user to a tenant and permission group based on the invitation.

  Retrieves or creates the user, associates them with the tenant, sets the
  current tenant, and adds them to the specified permission group.

  ## Parameters
    - _changeset: The Ash changeset (unused, kept for hook compatibility)
    - invitation: The invitation struct containing email, tenant, and group_id

  ## Returns
    - {:ok, invitation} on successful linking
    - {:error, reason} if any operation fails
  """
  def link_user_to_tenant(_changeset, invitation) do
    with {:ok, user} <- get_or_create_user(invitation),
         {:ok, _user_tenant} <- add_user_to_tenant(user.id, invitation.tenant),
         {:ok, _user_updated} <- set_user_current_tenant(user, invitation.tenant),
         {:ok, _user_group} <- add_user_to_group(user.id, invitation.group_id, invitation.tenant) do
      {:ok, invitation}
    else
      {:error, reason} ->
        {:error, "Failed to link user to tenant: #{inspect(reason)}"}
    end
  end

  defp get_tenant(tenant_name) do
    Framework.Accounts.Tenant
    |> Ash.Query.filter(domain == ^tenant_name)
    |> Ash.read_first(authorize?: false)
    |> case do
      {:ok, tenant} -> {:ok, tenant}
      {:error, reason} -> {:error, reason}
    end
  end

  defp add_user_to_tenant(user_id, tenant_name) do
    with {:ok, tenant} <- get_tenant(tenant_name) do
      Ash.Seed.seed!(
        Framework.Accounts.UserTenant,
        %{user_id: user_id, tenant_id: tenant.id},
        tenant: tenant_name
      )
      |> then(&{:ok, &1})
    end
  end

  defp set_user_current_tenant(user, tenant_name) do
    Ash.Seed.update!(user, %{current_tenant: tenant_name}, tenant: tenant_name)
    |> then(&{:ok, &1})
  end

  defp add_user_to_group(user_id, group_id, tenant_name) do
    Ash.Seed.seed!(
      Framework.Accounts.UserGroup,
      %{user_id: user_id, group_id: group_id},
      tenant: tenant_name
    )
    |> then(&{:ok, &1})
  end

  defp get_or_create_user(%{email: email, tenant: tenant_name}) do
    Framework.Accounts.User
    |> Ash.Query.filter(email == ^email)
    |> Ash.read_first(authorize?: false)
    |> case do
      {:ok, nil} -> create_user(email, tenant_name)
      {:ok, user} -> {:ok, user}
      {:error, reason} -> {:error, reason}
    end
  end

  defp create_user(email, tenant_name) do
    Ash.Seed.seed!(
      Framework.Accounts.User,
      %{email: email, current_tenant: tenant_name},
      tenant: tenant_name
    )
    |> then(&{:ok, &1})
  end
end
