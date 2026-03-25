defmodule Framework.Orders.Changes.ValidateConstraints do
  @moduledoc """
  Enforces order constraints based on Settings:
  - Lead time days for delivery_date
  - Global daily capacity (orders per day)
  - Per-item max daily quantity on the selected delivery date

  Applied on both create and update. For updates, global capacity check is
  skipped if delivery_date does not change. Per-item capacity excludes the
  current order's items when updating to avoid double counting.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias Framework.DecimalHelpers
  alias Framework.Orders.OrderItem

  @impl true
  def change(changeset, _opts, _ctx) do
    settings = safe_get_settings()

    case get_delivery_datetime(changeset) do
      {:ok, delivery_dt} ->
        # Lead time
        changeset = maybe_validate_lead_time(changeset, settings, delivery_dt)

        # Global daily capacity (orders per day)
        changeset = maybe_validate_global_capacity(changeset, settings, delivery_dt)

        # Per-item capacity
        changeset = maybe_validate_item_capacity(changeset, settings, delivery_dt)

        changeset

      _ ->
        # If no delivery date, skip validations
        changeset
    end
  end

  # -- Helpers --

  defp get_delivery_datetime(changeset) do
    case Changeset.get_attribute(changeset, :delivery_date) do
      %DateTime{} = dt ->
        {:ok, dt}

      nil ->
        case changeset.data do
          %{delivery_date: %DateTime{} = dt} -> {:ok, dt}
          _ -> :error
        end
    end
  end

  defp maybe_validate_lead_time(changeset, settings, %DateTime{} = delivery_dt) do
    lead_days = settings.lead_time_days || 0

    if lead_days > 0 do
      min_date = Date.add(Date.utc_today(), lead_days)

      if Date.before?(DateTime.to_date(delivery_dt), min_date) do
        Changeset.add_error(changeset,
          field: :delivery_date,
          message:
            "delivery date must be on or after #{Date.to_iso8601(min_date)} (lead time #{lead_days}d)"
        )
      else
        changeset
      end
    else
      changeset
    end
  end

  defp maybe_validate_global_capacity(changeset, settings, %DateTime{} = delivery_dt) do
    cap = settings.daily_capacity || 0

    if cap <= 0 do
      changeset
    else
      # Skip on update if the date did not change
      same_day_update? =
        case changeset.data do
          %{delivery_date: %DateTime{} = old_dt} ->
            DateTime.to_date(old_dt) == DateTime.to_date(delivery_dt)

          _ ->
            false
        end

      if same_day_update? do
        changeset
      else
        day = DateTime.to_date(delivery_dt)
        start_dt = DateTime.new!(day, ~T[00:00:00], "Etc/UTC")
        end_dt = DateTime.new!(day, ~T[23:59:59], "Etc/UTC")

        count =
          Framework.Orders.Order
          |> Ash.Query.for_read(:for_day, %{
            delivery_date_start: start_dt,
            delivery_date_end: end_dt
          })
          |> Ash.read!()
          |> length()

        if count >= cap do
          Changeset.add_error(changeset,
            field: :delivery_date,
            message: "daily capacity reached for #{Date.to_iso8601(day)} (#{cap})"
          )
        else
          changeset
        end
      end
    end
  end

  defp maybe_validate_item_capacity(changeset, _settings, %DateTime{} = delivery_dt) do
    # Build proposed quantities by item from arg or existing items
    {proposed_by_item, changeset} = proposed_quantities_by_item(changeset)

    if map_size(proposed_by_item) == 0 do
      changeset
    else
      day = DateTime.to_date(delivery_dt)
      start_dt = DateTime.new!(day, ~T[00:00:00], "Etc/UTC")
      end_dt = DateTime.new!(day, ~T[23:59:59], "Etc/UTC")

      item_ids = Map.keys(proposed_by_item)

      exclude_order_id =
        case changeset.data do
          %{id: id} when is_binary(id) -> id
          _ -> nil
        end

      existing_items =
        OrderItem
        |> Ash.Query.for_read(:in_range, %{
          start_date: start_dt,
          end_date: end_dt,
          item_ids: item_ids,
          exclude_order_id: exclude_order_id
        })
        |> Ash.read!()

      existing_by_item =
        existing_items
        |> Enum.group_by(& &1.item_id)
        |> Map.new(fn {pid, items} ->
          qty =
            Enum.reduce(items, Decimal.new(0), fn it, acc -> Decimal.add(acc, it.quantity) end)

          {pid, qty}
        end)

      # Load item caps in one go
      items =
        Framework.Project.Item
        |> Ash.Query.filter(id in ^item_ids)
        |> Ash.read!()
        |> Map.new(&{&1.id, &1})

      Enum.reduce(item_ids, changeset, fn pid, cs ->
        item = Map.get(items, pid)
        cap = (item && item.max_daily_quantity) || 0

        if cap <= 0 do
          cs
        else
          existing = Map.get(existing_by_item, pid, Decimal.new(0))
          proposed = Map.get(proposed_by_item, pid, Decimal.new(0))
          total = Decimal.add(existing, proposed)

          if Decimal.compare(total, Decimal.new(cap)) == :gt do
            name = (item && item.name) || pid

            Changeset.add_error(cs,
              field: :items,
              message: "#{name}: total #{Decimal.to_string(total)} exceeds daily capacity #{cap}"
            )
          else
            cs
          end
        end
      end)
    end
  end

  defp proposed_quantities_by_item(changeset) do
    items_arg = Changeset.get_argument(changeset, :items)

    if is_list(items_arg) do
      {sum_by_item(items_arg), changeset}
    else
      case changeset.data do
        %{items: items} when is_list(items) ->
          mapped =
            Enum.map(items, fn it -> %{item_id: it.item_id, quantity: it.quantity} end)

          {sum_by_item(mapped), changeset}

        %{id: _id} ->
          # If items are not preloaded, skip capacity validation here to avoid extra authorized reads
          {%{}, changeset}

        _ ->
          {%{}, changeset}
      end
    end
  end

  defp sum_by_item(items) do
    Enum.reduce(items, %{}, fn item, acc ->
      pid = Map.get(item, :item_id) || Map.get(item, "item_id")
      qty = DecimalHelpers.to_decimal(Map.get(item, :quantity) || Map.get(item, "quantity") || 0)

      if is_nil(pid) do
        acc
      else
        Map.update(acc, pid, qty, &Decimal.add(&1, qty))
      end
    end)
  end

  defp safe_get_settings do
    Framework.Settings.get_settings!()
  rescue
    _ -> %{lead_time_days: 0, daily_capacity: 0}
  end
end
