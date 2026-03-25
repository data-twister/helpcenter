defmodule Framework.KnowledgeBase.Comment do
  use Ash.Resource,
    domain: Framework.KnowledgeBase,
    data_layer: AshPostgres.DataLayer,
    extensions: [Framework.Extensions.AshParental]

  postgres do
    table "comments"
    repo Framework.Repo
  end

  ash_parental do
    distroy_with_children?(true)
  end

  actions do
    default_accept [:content, :article_id]
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
    attribute :content, :string, allow_nil?: false
    timestamps()
  end

  relationships do
    belongs_to :article, Framework.KnowledgeBase.Article do
      source_attribute :article_id
      allow_nil? false
    end
  end
end
