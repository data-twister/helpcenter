defmodule Framework.Project.BOMComponent do
  @moduledoc false
  use Ash.Resource,
    otp_app: :framework,
    domain: Framework.Project,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource, AshGraphql.Resource]

  alias Framework.Project.Changes.ValidateComponentTarget
  alias Framework.Project.Services.BOMRollup

  json_api do
    type "bom-component"

    routes do
      base("/bom-components")
      get(:read)
      index :read
    end
  end

  graphql do
    type :bom_component

    queries do
      get(:get_bom_component, :read)
      list(:list_bom_components, :read)
    end
  end

  postgres do
    table "project_bom_components"
    repo Framework.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :component_type,
        :quantity,
        :position,
        :waste_percent,
        :notes,
        :material_id,
        :item_id
      ]

      change {ValidateComponentTarget, []}

      change after_action(fn changeset, result, _ctx ->
               bom_id = Map.get(result, :bom_id) || Map.get(changeset.data, :bom_id)

               BOMRollup.refresh_by_bom_id!(
                 bom_id,
                 actor: changeset.context[:actor],
                 authorize?: false
               )

               {:ok, result}
             end)
    end

    update :update do
      primary? true
      require_atomic? false

      accept [
        :component_type,
        :quantity,
        :position,
        :waste_percent,
        :notes,
        :material_id,
        :item_id
      ]

      change {ValidateComponentTarget, []}

      change after_action(fn changeset, result, _ctx ->
               bom_id = Map.get(result, :bom_id) || Map.get(changeset.data, :bom_id)

               BOMRollup.refresh_by_bom_id!(
                 bom_id,
                 actor: changeset.context[:actor],
                 authorize?: false
               )

               {:ok, result}
             end)
    end
  end

  preparations do
    prepare Framework.Preparations.SetTenant
  end

  changes do
    change Framework.Changes.SetTenant
  end

  multitenancy do
    strategy :context
  end

  attributes do
    uuid_primary_key :id

    attribute :component_type, :atom do
      allow_nil? false
      default :material
      constraints one_of: [:material, :item]
    end

    attribute :quantity, :decimal do
      allow_nil? false
      default 0
      constraints min: 0
    end

    attribute :position, :integer do
      allow_nil? false
      default 0
      constraints min: 0
    end

    attribute :waste_percent, :decimal do
      allow_nil? false
      default 0
      constraints min: 0
    end

    attribute :notes, :string do
      allow_nil? true
    end

    timestamps()
  end

  relationships do
    belongs_to :bom, Framework.Project.BOM do
      allow_nil? false
    end

    belongs_to :material, Framework.Inventory.Material do
      allow_nil? true
      domain Framework.Inventory
    end

    belongs_to :item, Framework.Project.Item do
      allow_nil? true
    end
  end
end
