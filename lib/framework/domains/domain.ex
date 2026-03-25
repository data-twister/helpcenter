# lib/framework/accounts/domain.ex
defmodule Framework.Domains.Domain do
  use Ash.Resource,
    domain: Framework.Domains,
    data_layer: AshPostgres.DataLayer,
    notifiers: Ash.Notifier.PubSub

  postgres do
    table "domains"
    repo Framework.Repo
  end

  code_interface do
    define :list_domains, action: :read
  end

  actions do
    default_accept [:host, :auth_code, :status]
    defaults [:read, :update, :destroy]

    create :create do
      primary? true
      accept [:host, :tenant_id, :auth_code]

      change Framework.Domains.Changes.DomainCheck
    end
  end

  pub_sub do
    module FrameworkWeb.Endpoint

    prefix "domains"

    publish_all :update, [[:id, nil]]
    publish_all :create, [[:id, nil]]
    publish_all :destroy, [[:id, nil]]
  end

  preparations do
    prepare Framework.Preparations.SetTenant
  end

  changes do
    change Framework.Changes.SetTenant
  end

  multitenancy do
    strategy :attribute
    attribute :tenant_id
    global? true
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :host, :string do
      description "Domain host"
      allow_nil? false
    end

    attribute :auth_code, :string do
      description "Domain auth_code"
      allow_nil? false
    end

    attribute :status, :string do
      description "Domain status"
      allow_nil? false
    end

    attribute :attempts, :integer do
      description "Auth Attempts"
      default 0
    end

    timestamps()
  end

  relationships do
    belongs_to :tenant, Framework.Accounts.Tenant do
      allow_nil? true
    end
  end

  identities do
    identity :unique_name, [:host]
  end
end
