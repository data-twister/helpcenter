defmodule Framework.KnowledgeBase.ArticleFeedback do
  use Ash.Resource,
    domain: Framework.KnowledgeBase,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "article_feedbacks"
    repo Framework.Repo
  end

  actions do
    default_accept [:feedback, :helpful, :article_id]
    defaults [:create, :read, :update, :destroy]
  end

  preparations do
    prepare Framework.Preparations.SetTenant
  end

  changes do
    change Framework.Changes.SetTenant
    change Framework.Changes.InvalidateCache
  end

  multitenancy do
    strategy :context
  end

  attributes do
    uuid_primary_key :id

    attribute :helpful, :boolean, default: false
    attribute :feedback, :string, allow_nil?: true

    create_timestamp :created_at
  end

  relationships do
    belongs_to :article, Framework.KnowledgeBase.Article do
      source_attribute :article_id
      allow_nil? false
    end
  end
end
