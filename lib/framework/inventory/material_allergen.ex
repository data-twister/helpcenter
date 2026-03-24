defmodule Framework.Inventory.MaterialAllergen do
  @moduledoc false
  use Ash.Resource,
    otp_app: :framework,
    domain: Framework.Inventory,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Framework.Preparations.SetTenant

  postgres do
    table "inventory_material_allergen"
    repo Framework.Repo
  end

  actions do
    defaults [:read, :destroy, update: :*]

    create :create do
      primary? true
      accept [:allergen_id, :material_id]
    end
  end

  policies do
    # Public read (used for printable allergen listings and exports)
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type([:create, :update, :destroy]) do
      authorize_if expr(^actor(:role) in [:staff, :admin])
    end
  end

  preparations do
    prepare SetTenant
  end

  preparations do
    prepare SetTenant
  end

  changes do
    change Framework.Changes.SetTenant
  end

  changes do
    change Framework.Changes.SetTenant
  end

  multitenancy do
    strategy :context
  end

  relationships do
    belongs_to :material, Framework.Inventory.Material, primary_key?: true, allow_nil?: false
    belongs_to :allergen, Framework.Inventory.Allergen, primary_key?: true, allow_nil?: false
  end
end
