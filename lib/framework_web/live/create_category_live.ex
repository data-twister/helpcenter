defmodule FrameworkWeb.CreateCategoryLive do
  @moduledoc """
  Liveview module to create a new category into the database
  """
  use FrameworkWeb, :live_view

  def render(assigns) do
    ~H"""
    <%!-- Display link to take user back to category list --%>
    <.back navigate={~p"/categories"}>{gettext("Back to categories")}</.back>

    <FrameworkWeb.Categories.CategoryForm.form actor={@current_user} />
    """
  end
end
