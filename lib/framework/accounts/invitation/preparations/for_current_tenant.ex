defmodule Framework.Accounts.Invitation.Preparations.ForCurrentTenant do
  use Ash.Resource.Preparation

  def prepare(query, _options, %{actor: nil}), do: query

  def prepare(query, _opts, context) do
    %{current_tenant: tenant} = context.actor
    Ash.Query.filter(query, tenant == ^tenant)
  end
end
