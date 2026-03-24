defmodule Framework.Orders.Changes.AssignBatchCodeAndCost do
  @moduledoc false

  use Ash.Resource.Change

  import Ash.Expr

  alias Ash.Changeset
  alias Ash.NotLoaded
  alias Ash.Query
  alias Framework.Project
  alias Framework.Project.BOM
  alias Framework.Project.Item
  alias Framework.Project.Services.BatchCostCalculator
  alias Framework.DecimalHelpers
  alias Framework.Orders.OrderItem
  alias Decimal, as: D

  @impl true
  def change(changeset, _opts, _context) do
    if transitioning_to_done?(changeset) do
      apply_costing(changeset)
    else
      changeset
    end
  end

  defp apply_costing(changeset) do
    actor = actor_from(changeset)
    item = resolve_item(changeset, actor)

    case item do
      nil ->
        Changeset.add_error(changeset,
          field: :item_id,
          message: "item must be present to finalize batch costing"
        )

      %{sku: sku} ->
        quantity =
          Changeset.get_attribute(changeset, :quantity) || get_data_field(changeset, :quantity)

        batch_quantity = DecimalHelpers.to_decimal(quantity)
        bom = resolve_bom(changeset, item)
        authorize? = false

        costs =
          case bom do
            nil ->
              zero_costs()

            bom ->
              BatchCostCalculator.calculate(bom, batch_quantity,
                actor: actor,
                authorize?: authorize?
              )
          end

        changeset
        |> maybe_put_bom(bom)
        |> ensure_batch_code(sku, actor, authorize?)
        |> Changeset.force_change_attribute(
          :material_cost,
          Map.get(costs, :material_cost, D.new(0))
        )
        |> Changeset.force_change_attribute(:labor_cost, Map.get(costs, :labor_cost, D.new(0)))
        |> Changeset.force_change_attribute(
          :overhead_cost,
          Map.get(costs, :overhead_cost, D.new(0))
        )
        |> Changeset.force_change_attribute(:unit_cost, Map.get(costs, :unit_cost, D.new(0)))
    end
  end

  defp transitioning_to_done?(changeset) do
    case {Changeset.changing_attribute?(changeset, :status),
          Changeset.get_attribute(changeset, :status)} do
      {true, :done} ->
        current_status = get_data_field(changeset, :status)
        current_status != :done

      _ ->
        false
    end
  end

  defp ensure_batch_code(changeset, sku, actor, authorize?) do
    case Changeset.get_attribute(changeset, :batch_code) || get_data_field(changeset, :batch_code) do
      nil ->
        code = generate_batch_code(sku, actor, authorize?)
        Changeset.force_change_attribute(changeset, :batch_code, code)

      _existing ->
        changeset
    end
  end

  defp generate_batch_code(sku, actor, authorize?) do
    date = Date.utc_today()
    date_str = Calendar.strftime(date, "%Y%m%d")
    prefix = "B-#{date_str}-#{sku}"

    next_seq =
      OrderItem
      |> Query.new()
      |> Query.filter(
        expr(not is_nil(batch_code) and fragment("? LIKE ?", batch_code, ^"#{prefix}-%"))
      )
      |> Query.sort(batch_code: :desc)
      |> Query.limit(1)
      |> Ash.read_one(actor: actor, authorize?: authorize?)
      |> case do
        {:ok, nil} ->
          1

        {:ok, %{batch_code: batch_code}} ->
          batch_code
          |> String.split("-")
          |> List.last()
          |> to_integer(0)
          |> Kernel.+(1)

        _ ->
          1
      end

    "#{prefix}-#{String.pad_leading(Integer.to_string(next_seq), 3, "0")}"
  end

  defp maybe_put_bom(changeset, nil), do: changeset

  defp maybe_put_bom(changeset, bom) do
    Changeset.force_change_attribute(changeset, :bom_id, bom.id)
  end

  defp resolve_item(changeset, actor) do
    case get_data_field(changeset, :item) do
      %Item{} = item -> maybe_load_active_bom(item, actor)
      _ -> fetch_item(changeset, actor)
    end
  end

  defp fetch_item(changeset, actor) do
    item_id =
      Changeset.get_attribute(changeset, :item_id) ||
        get_data_field(changeset, :item_id)

    with id when not is_nil(id) <- item_id,
         {:ok, item} <-
           Catalog.get_item_by_id(id,
             actor: actor,
             authorize?: false,
             load: [:active_bom]
           ) do
      item
    else
      _ -> nil
    end
  end

  defp maybe_load_active_bom(%Item{} = item, actor) do
    case Map.get(item, :active_bom) do
      %NotLoaded{} ->
        case Ash.load(item, [:active_bom], actor: actor, authorize?: false) do
          {:ok, loaded} -> loaded
          _ -> item
        end

      _ ->
        item
    end
  end

  defp fetch_active_bom(nil, _actor), do: nil

  defp fetch_active_bom(item, actor) do
    BOM
    |> Query.for_read(:get_active, %{item_id: item.id})
    |> Ash.read_one(actor: actor, authorize?: false)
    |> case do
      {:ok, bom} -> bom
      _ -> nil
    end
  end

  defp resolve_bom(changeset, item) do
    actor = actor_from(changeset)

    with id when not is_nil(id) <- Changeset.get_attribute(changeset, :bom_id),
         {:ok, bom} <- Ash.get(BOM, id, actor: actor, authorize?: false) do
      bom
    else
      _ ->
        case item do
          nil ->
            fetch_active_bom(item, actor)

          %Item{} ->
            case Map.get(item, :active_bom) do
              %BOM{} = bom -> bom
              _ -> fetch_active_bom(item, actor)
            end
        end
    end
  end

  defp get_data_field(changeset, field) do
    case Changeset.get_data(changeset, field) do
      {:ok, value} -> value
      :error -> Map.get(changeset.data, field)
      %NotLoaded{} -> Map.get(changeset.data, field)
      value -> value
    end
  rescue
    _ -> Map.get(changeset.data, field)
  end

  defp zero_costs do
    %{material_cost: D.new(0), labor_cost: D.new(0), overhead_cost: D.new(0), unit_cost: D.new(0)}
  end

  defp actor_from(changeset) do
    Map.get(changeset.context, :actor)
  end

  defp to_integer(string, default) when is_binary(string) do
    case Integer.parse(string) do
      {int, _} -> int
      :error -> default
    end
  end

  defp to_integer(_, default), do: default
end
