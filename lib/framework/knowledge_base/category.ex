# lib/framework/knowledge_base/category.ex
defmodule Framework.KnowledgeBase.Category do
  use Ash.Resource,
    domain: Framework.KnowledgeBase,
    data_layer: AshPostgres.DataLayer,
    notifiers: Ash.Notifier.PubSub,
    authorizers: Ash.Policy.Authorizer

  postgres do
    table "categories"
    repo Framework.Repo
  end

  actions do
    default_accept [:name, :slug, :description]
    defaults [:create, :read, :update, :destroy]

    read :most_recent do
      prepare Framework.Preparations.LimitTo5
      prepare Framework.Preparations.MonthToDate
      prepare Framework.Preparations.OrderByMostRecent
    end

    create :create_with_article do
      description "Create a Category and an article under it"
      argument :article_attrs, :map, allow_nil?: false
      change manage_relationship(:article_attrs, :articles, type: :create)
    end

    update :add_article do
      description "Add an article under a specified category"
      require_atomic? false
      argument :article_attrs, :map, allow_nil?: false
      change manage_relationship(:article_attrs, :articles, type: :create)
    end
  end

  policies do
    policy always() do
      access_type :strict
      authorize_if Framework.Accounts.Checks.Authorized
    end
  end

  # Confirm how Ash will wor
  pub_sub do
    # 1. Tell Ash to use FrameworkWeb.Endpoint for publishing events
    module FrameworkWeb.Endpoint

    # Prefix all events from this resource with category. This allows us
    # to subscribe only to events starting with "categories" in livew view
    prefix "categories"

    # Define event topic or names. Below configuration will be publishing
    # topic of this format whenever an action of update, create or delete
    # happens:
    #    "categories"
    #    "categories:UUID-PRIMARY-KEY-ID-OF-CATEGORY"
    #
    #  You can pass any other parameter available on resource like slug

    publish_all :update, [[:id, nil]]
    publish_all :create, [[:id, nil]]
    publish_all :destroy, [[:id, nil]]
  end

  preparations do
    prepare Framework.Preparations.SetTenant
  end

  changes do
    change Framework.Changes.Slugify

    change Framework.Changes.SetTenant
  end

  multitenancy do
    strategy :context
  end

  # Tell Ash what columns or attributes this resource has and their types and validations
  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :slug, :string
    attribute :description, :string, allow_nil?: true

    attribute :parent_id, :uuid, allow_nil?: true

    timestamps()
  end

  # Relationship Block. In this case this resource has many articles
  relationships do
    has_many :articles, Framework.KnowledgeBase.Article do
      description "Relationship with the articles."

      # <-- Tell Ash that the articles table has a column named "category_id" that references this resource
      destination_attribute :category_id
    end
  end

  aggregates do
    count :article_count, :articles
  end
end
