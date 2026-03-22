defmodule Framework.KnowledgeBase.ArticleTag do
  use Ash.Resource,
    domain: Framework.KnowledgeBase,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "article_tags"
    repo Framework.Repo
  end

  actions do
    default_accept [:article_id, :tag_id]
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
    timestamps()
  end

  relationships do
    belongs_to :article, Framework.KnowledgeBase.Article do
      source_attribute :article_id
    end

    belongs_to :tag, Framework.KnowledgeBase.Tag do
      source_attribute :tag_id
    end
  end

  identities do
    identity :unique_article_tag, [:article_id, :tag_id]
  end
end
