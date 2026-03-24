defmodule Framework.Project.Item do
  @moduledoc false
  use Ash.Resource,
    otp_app: :framework,
    domain: Framework.Project,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshJsonApi.Resource, AshGraphql.Resource]

  alias Framework.Project.BOM

  json_api do
    type "item"

    routes do
      base("/items")
      get(:read)
      index :list
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  graphql do
    type :item

    queries do
      get(:get_item, :read)
      list(:list_items, :list)
    end

    mutations do
      create :create_item, :create
      update :update_item, :update
      destroy :destroy_item, :destroy
    end
  end

  postgres do
    table "project_items"
    repo Framework.Repo
  end

  actions do
    defaults [
      :read,
      :destroy,
      create: [
        :name,
        :status,
        :price,
        :sku,
        :photos,
        :featured_photo,
        :selling_availability,
        :max_daily_quantity
      ],
      update: [
        :name,
        :status,
        :price,
        :sku,
        :photos,
        :featured_photo,
        :selling_availability,
        :max_daily_quantity
      ]
    ]

    read :list do
      prepare build(sort: :name)

      argument :status, {:array, :atom} do
        allow_nil? true
        default nil
      end

      filter expr(is_nil(^arg(:status)) or status in ^arg(:status))

      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end
    end

    read :keyset do
      prepare build(sort: :name)
      pagination keyset?: true
    end
  end

  policies do
    # API key scope check
    policy always() do
      authorize_if always()
    #  authorize_if {Framework.Accounts.Checks.ApiScopeCheck, []}
    end

    policy action_type([:create, :read, :update, :destroy]) do
      authorize_if always()
   #   forbid_unless Framework.Accounts.Checks.ActorBelongsToTenant
    end

    # Admin can do anything
    bypass expr(^actor(:role) == :admin) do
      authorize_if always()
    end

    # Public read for active/available items; staff/admin read everything
    policy action_type(:read) do
      authorize_if expr(status == :active or selling_availability != :off)
      authorize_if expr(^actor(:role) in [:staff, :admin])
    end

    # Writes restricted to staff/admin
    policy action_type([:create, :update, :destroy]) do
      authorize_if expr(^actor(:role) in [:staff, :admin])
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

    attribute :name, :string do
      allow_nil? false
      public? true

      constraints min_length: 2,
                  max_length: 100,
                  match: ~r/^[\w\s\-\.]+$/
    end

    attribute :status, Framework.Project.Item.Types.Status do
      allow_nil? false
      public? true
      default :draft
    end

    attribute :price, :decimal do
      public? true
      allow_nil? false
    end

    attribute :sku, :string do
      allow_nil? false
    end

    attribute :photos, {:array, :string} do
      public? true
      default []
      description "Array of photo URLs for the item"
    end

    attribute :featured_photo, :string do
      public? true
      allow_nil? true
      description "ID or reference to the featured photo from the photos array"
    end

    attribute :selling_availability, :atom do
      public? true
      allow_nil? false
      default :available
      constraints one_of: [:available, :preorder, :off]
      description "Customer-facing availability: available, preorder, or off"
    end

    attribute :max_daily_quantity, :integer do
      public? true
      allow_nil? false
      default 0
      constraints min: 0
      description "Optional per-item capacity per day (0 = unlimited)"
    end

    timestamps()
  end

  relationships do
    has_many :boms, BOM

    has_one :active_bom, BOM do
      filter expr(status == :active)
    end

    has_many :items, Framework.Orders.OrderItem
  end

  calculations do
    calculate :materials_cost, :decimal, Framework.Project.Item.Calculations.MaterialCost do
      description "Material cost per unit based on the active BOM."
    end

    calculate :bom_unit_cost, :decimal, Framework.Project.Item.Calculations.UnitCost do
      description "Total unit cost (materials + labor + overhead) derived from the active BOM."
    end

    calculate :markup_percentage,
              :decimal,
              Framework.Project.Item.Calculations.MarkupPercentage do
      description "The ratio of profit to cost, expressed as a decimal percentage"
    end

    calculate :gross_profit, :decimal, Framework.Project.Item.Calculations.GrossProfit do
      description "The profit amount calculated as selling price minus unit cost"
    end

    calculate :allergens, :vector, Framework.Project.Item.Calculations.Allergens

    calculate :nutritional_facts,
              :vector,
              Framework.Project.Item.Calculations.NutritionalFacts
  end

  identities do
    identity :sku, [:sku]
    identity :name, [:name]
  end
end
