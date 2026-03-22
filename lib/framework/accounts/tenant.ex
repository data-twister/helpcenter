defmodule Framework.Accounts.Tenant do
  require Ash.Resource.Change.Builtins

  use Ash.Resource,
    domain: Framework.Accounts,
    data_layer: AshPostgres.DataLayer

  @doc """
  Tell ash to use domain as the tenant database prefix when we are using
  postgresql as the database, otherwise use the ID
  """
  defimpl Ash.ToTenant do
    def to_tenant(resource, %{:domain => domain, :id => id}) do
      if Ash.Resource.Info.data_layer(resource) == AshPostgres.DataLayer &&
           Ash.Resource.Info.multitenancy_strategy(resource) == :context do
        domain
      else
        id
      end
    end
  end

  postgres do
    table "tenants"
    repo Framework.Repo

    manage_tenant do
      template ["", :domain]
      create? true
      update? false
    end
  end

  code_interface do
    # the action open can be omitted because it matches the function name
    define :by_domain, args: [:domain], action: :by_domain
  end

  actions do
    default_accept [:name, :domain, :description, :owner_user_id]
    defaults [:read]

    create :create do
      primary? true
      change Framework.Accounts.Tenant.Changes.AssociateUserToTenant
      change Framework.Accounts.Tenant.Changes.SetOwnerCurrentTenantAfterCreate
    end

    read :by_domain do
      description "This action is used to read a tenant by its domain"
      filter expr(domain == ^arg(:domain))
    end
  end

  preparations do
    prepare build(load: [:settings])
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
      description "Tenant or organisation name"
    end

    attribute :domain, :string do
      allow_nil? false
      public? true
      description "Domain name of the tenant or organisation"
    end

    attribute :description, :string, allow_nil?: true, public?: true

    timestamps()
  end

  relationships do

    has_one :settings, Framework.Settings.Setting

    belongs_to :owner, Framework.Accounts.User do
      source_attribute :owner_user_id
    end

    many_to_many :users, Framework.Accounts.User do
      through Framework.Accounts.UserTenant
      source_attribute_on_join_resource :tenant_id
      destination_attribute_on_join_resource :user_id
    end
  end

  identities do
    identity :unique_domain, [:domain] do
      description "Identity to find a tenant by its domain"
    end
  end
end
