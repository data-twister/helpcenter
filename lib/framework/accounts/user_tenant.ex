defmodule Framework.Accounts.UserTenant do
  use Ash.Resource,
    domain: Framework.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "user_tenants"
    repo Framework.Repo
  end

  resource do
    # We don't need primary key for this resource
    require_primary_key? false
  end

  actions do
    default_accept [:user_id, :tenant_id]
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_v7_primary_key :id
    timestamps()
  end

  relationships do
    belongs_to :user, Framework.Accounts.User do
      source_attribute :user_id
    end

    belongs_to :tenant, Framework.Accounts.Tenant do
      source_attribute :tenant_id
    end
  end

  identities do
    identity :unique_article_tag, [:user_id, :tenant_id]
  end
end
