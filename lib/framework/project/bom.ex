defmodule Framework.Project.BOM do
  @moduledoc false
  use Ash.Resource,
    otp_app: :framework,
    domain: Framework.Project,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource, AshGraphql.Resource]

  alias Framework.Project.Changes.AssignBOMVersion
  alias Framework.Project.Services.BOMRollup

  json_api do
    type "bom"

    routes do
      base("/boms")
      get(:read)
      index :list_for_item
    end
  end

  graphql do
    type :bom

    queries do
      get(:get_bom, :read)
      list(:list_boms, :list_for_item)
    end
  end

  postgres do
    table "project_boms"
    repo Framework.Repo

    custom_indexes do
      index [:item_id],
        unique: true,
        name: "project_boms_one_active_per_item",
        where: "status = 'active'"
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [:name, :notes, :status, :item_id, :published_at]

      argument :components, {:array, :map}
      argument :labor_steps, {:array, :map}

      change manage_relationship(:components, type: :direct_control)
      change manage_relationship(:labor_steps, type: :direct_control)
      change {AssignBOMVersion, []}

      change after_action(fn changeset, result, _ctx ->
               BOMRollup.refresh!(result,
                 actor: changeset.context[:actor],
                 authorize?: false
               )

               {:ok, result}
             end)
    end

    update :update do
      require_atomic? false

      accept [:name, :notes, :status, :published_at]

      argument :components, {:array, :map}
      argument :labor_steps, {:array, :map}

      change manage_relationship(:components, type: :direct_control)
      change manage_relationship(:labor_steps, type: :direct_control)

      change after_action(fn changeset, result, _ctx ->
               BOMRollup.refresh!(result,
                 actor: changeset.context[:actor],
                 authorize?: false
               )

               {:ok, result}
             end)
    end

    update :promote do
      require_atomic? false

      change set_attribute(:status, :active)

      change fn cs, _ ->
        Ash.Changeset.change_attribute(cs, :published_at, DateTime.utc_now())
      end

      change after_action(fn changeset, result, _ctx ->
               BOMRollup.refresh!(result,
                 actor: changeset.context[:actor],
                 authorize?: false
               )

               {:ok, result}
             end)
    end

    read :list_for_item do
      argument :item_id, :uuid, allow_nil?: false

      prepare build(
                sort: [version: :desc],
                filter: expr(item_id == ^arg(:item_id))
              )
    end

    read :get_active do
      get? true

      argument :item_id, :uuid, allow_nil?: false

      prepare build(
                sort: [version: :desc],
                filter: expr(item_id == ^arg(:item_id) and status == :active)
              )
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
      public? true
    end

    attribute :notes, :string do
      public? true
    end

    attribute :status, :atom do
      allow_nil? false
      default :draft
      constraints one_of: [:draft, :active, :archived]
      public? true
    end

    attribute :version, :integer do
      allow_nil? false
      writable? false
    end

    attribute :published_at, :utc_datetime do
      allow_nil? true
    end

    timestamps()
  end

  relationships do
    belongs_to :item, Framework.Project.Item do
      allow_nil? false
    end

    has_many :components, Framework.Project.BOMComponent

    has_many :labor_steps, Framework.Project.LaborStep

    has_one :rollup, Framework.Project.BOMRollup
  end

  identities do
    identity :item_version, [:item_id, :version]
  end
end
