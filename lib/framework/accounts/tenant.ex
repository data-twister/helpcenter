defmodule Framework.Accounts.Tenant do
  require Ash.Resource.Change.Builtins

  use Ash.Resource,
    domain: Framework.Accounts,
    data_layer: AshPostgres.DataLayer

  # , extensions: [Framework.Extensions.AshHaikunator]

  #  alias Framework.Accounts.{Tenant, TenantDomain}
  #
  #  def resolve(host) when is_binary(host) do
  #    # 1. exact domain match (custom domains)
  #    case TenantDomain
  #         |> Ash.Query.filter(domain == ^host and verified == true)
  #         |> Ash.read_one() do
  #      {:ok, %{tenant: tenant}} ->
  #        {:ok, tenant}
  #
  #      _ ->
  #        # 2. fallback to subdomain
  #        resolve_subdomain(host)
  #    end
  #  end
  #
  #  defp resolve_subdomain(host) do
  #    case String.split(host, ".") do
  #      [sub, _root, _tld] ->
  #        Tenant.by_prefix(sub)
  #
  #      _ ->
  #        {:error, :no_tenant}
  #    end
  #  end

  @doc """
  Tell ash to use domain as the tenant database prefix when we are using
  postgresql as the database, otherwise use the ID
  """
  defimpl Ash.ToTenant do
    def to_tenant(resource, %{:prefix => prefix, :id => id}) do
      if Ash.Resource.Info.data_layer(resource) == AshPostgres.DataLayer &&
           Ash.Resource.Info.multitenancy_strategy(resource) == :context do
        prefix
      else
        id
      end
    end
  end

  postgres do
    table "tenants"
    repo Framework.Repo

    manage_tenant do
      template ["", :prefix]
      create? true
      update? false
    end
  end

  code_interface do
    # the action open can be omitted because it matches the function name
    define :by_domain, args: [:domain], action: :by_domain
    define :by_prefix, args: [:prefix], action: :by_prefix
  end

  actions do
    default_accept [:name, :domain, :prefix, :description, :owner_user_id]
    defaults [:read]

    create :create do
      primary? true
      change Framework.Accounts.Tenant.Changes.Slugify
      change Framework.Accounts.Tenant.Changes.AssociateUserToTenant
      change Framework.Accounts.Tenant.Changes.SetOwnerCurrentTenantAfterCreate
    end

    read :by_domain do
      description "This action is used to read a tenant by its domain"
      filter expr(domain == ^arg(:domain))
    end

    read :by_prefix do
      description "This action is used to read a tenant by its prefix"
      filter expr(prefix == ^arg(:prefix))
    end

    read :list_origins do
      description "list only the domains"
      prepare build(select: [:domain])
    end
  end

  #  preparations do
  #    prepare build(load: [:settings])
  #  end

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

    attribute :prefix, :string do
      allow_nil? true
      public? true
      description "Table Prefix for the tenant"
    end

    attribute :description, :string, allow_nil?: true, public?: true

    timestamps()
  end

  relationships do
    #    has_one :settings, Framework.Settings.Setting

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
