# lib/framework_web/controllers/page_controller.ex
defmodule FrameworkWeb.PageController do
  alias Framework.KnowledgeBase.Category
  use FrameworkWeb, :controller

  def home(conn, _params) do
    tenant = conn.assigns[:tenant]

    key =
      case tenant do
        nil -> conn.request_path
        t -> "#{t.id}:#{conn.request_path}"
      end

    #    categories = FrameworkWeb.Cache.get_or_fetch(key, fn ->
    #        Ash.read!(Category, tenant: tenant)
    #      end)

    categories = []
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false, categories: categories)
  end
end
