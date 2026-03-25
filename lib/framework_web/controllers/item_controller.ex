defmodule FrameworkWeb.ItemController do
  use FrameworkWeb, :controller

  def index(conn, params) do
    tenant = conn.assigns[:tenant]

    # Cached read with tenant isolation
    items =
      FrameworkWeb.Cache.read!(
        Framework.Project.Item,
        tenant: tenant,
        action: :list,
        params: params,
        ttl: :timer.minutes(10)
      )

    json(conn, items)
  end

  def show(conn, %{"id" => id}) do
    tenant = conn.assigns[:tenant]

    # Cached get by ID
    item =
      FrameworkWeb.Cache.get!(
        Framework.Project.Item,
        id,
        tenant: tenant,
        ttl: :timer.minutes(5)
      )

    json(conn, item)
  end

  def create(conn, %{"item" => item_params}) do
    tenant = conn.assigns[:tenant]

    case Ash.create(Framework.Project.Item, item_params, tenant: tenant) do
      {:ok, item} ->
        # Cache automatically invalidated via change module
        json(conn, item)

      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: error})
    end
  end

  def update(conn, %{"id" => id, "item" => item_params}) do
    tenant = conn.assigns[:tenant]

    item = Ash.get!(Framework.Project.Item, id, tenant: tenant)

    case Ash.update(item, item_params) do
      {:ok, updated_item} ->
        # Cache automatically invalidated
        json(conn, updated_item)

      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: error})
    end
  end
end
