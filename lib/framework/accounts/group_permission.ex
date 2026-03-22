# lib/framework/accounts/group_permission.ex
defmodule Framework.Accounts.GroupPermission do
  use Ash.Resource,
    domain: Framework.Accounts,
    data_layer: AshPostgres.DataLayer,
    notifiers: Ash.Notifier.PubSub

  postgres do
    table "group_permissions"
    repo Framework.Repo
  end

  actions do
    default_accept [:resource, :action, :group_id]
    defaults [:create, :read, :update, :destroy]
  end

  preparations do
    prepare Framework.Preparations.SetTenant
  end

  changes do
    change Framework.Changes.SetTenant
  end

  multitenancy do
    strategy :context
  end

  attributes do
    uuid_v7_primary_key :id
    attribute :action, :string, allow_nil?: false
    attribute :resource, :string, allow_nil?: false
    timestamps()
  end

  relationships do
    belongs_to :group, Framework.Accounts.Group do
      description "Relationshp with a group inside a tenant"
      source_attribute :group_id
      allow_nil? false
    end
  end

  identities do
    identity :unique_group_permission, [:group_id, :resource, :action]
  end
end
