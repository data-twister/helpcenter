defmodule FrameworkWeb.EditCategoryLive do
  @moduledoc """
  Edits an existing categroy
  """
  use FrameworkWeb, :live_view

  def render(assigns) do
    ~H"""
    <%!-- Display link to take user back to category list --%>
    <.back navigate={~p"/categories"}>{gettext("Back to categories")}</.back>
    <FrameworkWeb.Categories.CategoryForm.form category_id={@category_id} actor={@current_user} />
    """
  end

  def mount(%{"category_id" => category_id} = _params, _session, socket) do
    socket
    |> assign(:category_id, category_id)
    |> ok()
  end
end
