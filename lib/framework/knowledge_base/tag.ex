defmodule Framework.KnowledgeBase.Tag do
  use Ash.Resource,
    domain: Framework.KnowledgeBase,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tags"
    repo Framework.Repo
  end

  actions do
    default_accept [:name]
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
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    timestamps()
  end

  relationships do
    many_to_many :articles, Framework.KnowledgeBase.Article do
      through Framework.KnowledgeBase.ArticleTag
      source_attribute_on_join_resource :tag_id
      destination_attribute_on_join_resource :article_id
    end
  end
end
