# lib/framework/accounts/tenant_domain.ex
defmodule Framework.Accounts.TenantDomain do
  use Ash.Resource,
    domain: Framework.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tenant_domains"
    repo Framework.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :domain, :string do
      allow_nil? false
    end

    attribute :verified, :boolean do
      default false
    end
  end

  relationships do
    belongs_to :tenant, Framework.Accounts.Tenant
  end

  identities do
    identity :unique_domain, [:domain]
  end
end
