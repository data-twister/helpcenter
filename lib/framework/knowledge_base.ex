defmodule Framework.KnowledgeBase do
  # <-- Indicates that this file is Ash resource
  use Ash.Domain

  # `resources` is a macro A.K.A DSL to indicate that this sections lists resources under this domain
  resources do
    # `resource` is a marco indicating a resource under this domain
    resource Framework.KnowledgeBase.Category
    resource Framework.KnowledgeBase.Article
    resource Framework.KnowledgeBase.Tag
    resource Framework.KnowledgeBase.ArticleTag
    resource Framework.KnowledgeBase.Comment
    resource Framework.KnowledgeBase.ArticleFeedback
  end
end
