# lib/framework/accounts/group.ex
defmodule Framework.Accounts.Group do
  use Ash.Resource,
    domain: Framework.Accounts,
    data_layer: AshPostgres.DataLayer,
    notifiers: Ash.Notifier.PubSub

  postgres do
    table "groups"
    repo Framework.Repo
  end

  code_interface do
    define :list_groups, action: :read
  end

  actions do
    default_accept [:name, :description]
    defaults [:create, :read, :update, :destroy]
  end

  pub_sub do
    module FrameworkWeb.Endpoint

    prefix "groups"

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
    strategy :context
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :name, :string do
      description "Group name unique name"
      allow_nil? false
    end

    attribute :description, :string do
      description "Describes the intention of the group"
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    many_to_many :users, Framework.Accounts.User do
      through Framework.Accounts.UserGroup
      source_attribute_on_join_resource :group_id
      destination_attribute_on_join_resource :user_id
    end

    # lib/framework/accounts/group.ex
    has_many :permissions, Framework.Accounts.GroupPermission do
      description "List of permission assigned to this group"
      destination_attribute :group_id
    end
  end

  identities do
    identity :unique_name, [:name]
  end
end
