defmodule Framework.Project do
  @moduledoc false
  use Ash.Domain,
    extensions: [AshJsonApi.Domain, AshGraphql.Domain]

  json_api do
    prefix "/api/json"
  end

  graphql do
  end

  @type item_id :: integer()

  resources do
    resource Framework.Project.Item do
      define :get_item_by_id, action: :read, get_by: [:id]
      define :get_item_by_sku, action: :read, get_by: [:sku]
      define :list_items, action: :list
      define :list_items_with_keyset, action: :keyset
      define :destroy_item, action: :destroy
      define :update_item, action: :update
    end

    resource Framework.Project.BOM do
      define :list_boms_for_item, action: :list_for_item
      define :get_active_bom_for_item, action: :get_active
      define :create_bom, action: :create
      define :update_bom, action: :update
    end

    resource Framework.Project.BOMRollup
    resource Framework.Project.BOMComponent
    resource Framework.Project.LaborStep
    # Recipes removed (BOM-only)
  end
end
