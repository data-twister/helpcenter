defmodule Framework.Project.Services.BOMRecipeSync do
  @moduledoc false

  alias Ash.NotLoaded
  alias Framework.Project
  alias Framework.Project.BOM

  @load_paths [components: [:material, :item], labor_steps: []]

  @spec load_bom_for_item(Framework.Project.Item.t(), keyword) :: BOM.t()
  def load_bom_for_item(item, opts \\ []) do
    actor = Keyword.get(opts, :actor)
    authorize? = Keyword.get(opts, :authorize?, false)

    item
    |> ensure_active_bom(actor, authorize?)
    |> ensure_loaded(actor, authorize?)
  end

  defp ensure_active_bom(item, actor, authorize?) do
    case Map.get(item, :active_bom) do
      %NotLoaded{} ->
        fetch_active_bom(item, actor, authorize?)

      nil ->
        fetch_active_bom(item, actor, authorize?)

      bom ->
        bom
    end
  end

  defp fetch_active_bom(item, actor, authorize?) do
    case Project.get_active_bom_for_item(%{item_id: item.id},
           actor: actor,
           authorize?: authorize?
         ) do
      {:ok, %BOM{} = bom} ->
        bom

      _ ->
        # Fallback to latest BOM by version if no active exists
        case Project.list_boms_for_item(%{item_id: item.id},
               actor: actor,
               authorize?: authorize?
             ) do
          {:ok, [latest | _]} -> latest
          _ -> new_bom(item)
        end
    end
  end

  defp new_bom(item) do
    %BOM{
      item_id: item.id,
      status: :draft,
      components: [],
      labor_steps: []
    }
  end

  defp ensure_loaded(%BOM{id: nil} = bom, _actor, _authorize?), do: bom

  defp ensure_loaded(%BOM{} = bom, actor, authorize?) do
    Ash.load!(bom, @load_paths,
      actor: actor,
      authorize?: authorize?
    )
  end

  # No recipe population/sync (BOM-only)
end
