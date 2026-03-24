# lib/framework_web/controllers/page_controller.ex
defmodule FrameworkWeb.PageController do
  alias Framework.KnowledgeBase.Category
  use FrameworkWeb, :controller

  def home(conn, _params) do
    # TODO: load the default tenant

    # Retrieve categories with the articles
    categories =
      if tenant = Ash.read_first!(Framework.Accounts.Tenant) do
        Ash.read!(Category, load: :article_count, tenant: tenant.prefix, authorize?: false)
      else
        []
      end

    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false, categories: categories)
  end
end
