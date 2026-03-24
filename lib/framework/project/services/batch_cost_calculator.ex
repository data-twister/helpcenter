defmodule Framework.Project.Services.BatchCostCalculator do
  @moduledoc false

  alias Framework.Project
  alias Framework.Project.BOM
  alias Framework.Project.BOMComponent
  alias Framework.DecimalHelpers
  alias Framework.Settings
  alias Decimal, as: D

  @spec calculate(BOM.t(), number | D.t(), keyword) :: %{
          material_cost: D.t(),
          labor_cost: D.t(),
          overhead_cost: D.t(),
          unit_cost: D.t()
        }
  def calculate(%BOM{} = bom, quantity, opts \\ []) do
    settings = fetch_settings(opts)
    path = MapSet.new()

    do_calculate(bom, DecimalHelpers.to_decimal(quantity), opts, settings, path)
  end

  @spec do_calculate(BOM.t(), D.t(), keyword(), map(), MapSet.t()) :: %{
          material_cost: D.t(),
          labor_cost: D.t(),
          overhead_cost: D.t(),
          unit_cost: D.t()
        }
  defp do_calculate(%BOM{} = bom, quantity, opts, settings, path) do
    authorize? = Keyword.get(opts, :authorize?, true)
    actor = Keyword.get(opts, :actor)

    bom =
      Ash.load!(
        bom,
        [components: [:material, :item], labor_steps: []],
        actor: actor,
        authorize?: authorize?
      )

    quantity = DecimalHelpers.to_decimal(quantity)

    path = maybe_track_item(path, bom.item_id)

    material_cost =
      bom.components
      |> Enum.sort_by(& &1.position)
      |> Enum.reduce(D.new(0), fn component, acc ->
        cost = component_cost(component, quantity, opts, settings, path)
        D.add(acc, cost)
      end)

    labor_cost = labor_cost(bom.labor_steps, quantity, settings)
    overhead_cost = overhead_cost(material_cost, labor_cost, settings)

    total_cost =
      material_cost
      |> D.add(labor_cost)
      |> D.add(overhead_cost)

    unit_cost =
      if D.compare(quantity, D.new(0)) == :gt do
        D.div(total_cost, quantity)
      else
        D.new(0)
      end

    %{
      material_cost: material_cost,
      labor_cost: labor_cost,
      overhead_cost: overhead_cost,
      unit_cost: unit_cost
    }
  end

  @spec component_cost(BOMComponent.t(), D.t(), keyword(), map(), MapSet.t()) :: D.t()
  defp component_cost(
         %BOMComponent{component_type: :material} = component,
         quantity,
         _opts,
         _settings,
         _path
       ) do
    multiplier = waste_multiplier(component)

    total_quantity =
      quantity |> D.mult(DecimalHelpers.to_decimal(component.quantity)) |> D.mult(multiplier)

    price =
      case component.material do
        %{price: price} -> DecimalHelpers.to_decimal(price)
        _ -> D.new(0)
      end

    D.mult(total_quantity, price)
  end

  defp component_cost(
         %BOMComponent{component_type: :item} = component,
         quantity,
         opts,
         settings,
         path
       ) do
    total_quantity =
      quantity
      |> D.mult(DecimalHelpers.to_decimal(component.quantity))
      |> D.mult(waste_multiplier(component))

    actor = Keyword.get(opts, :actor)
    authorize? = Keyword.get(opts, :authorize?, true)

    with {:ok, item} <- get_item_from_component(component),
         :ok <- check_for_circular_dependency(item.id, path),
         {:ok, bom} <- get_active_bom_for_item(item.id, actor, authorize?) do
      nested_cost = calculate_nested_cost(bom, opts, settings, MapSet.put(path, item.id))
      D.mult(total_quantity, nested_cost)
    else
      _error ->
        # Fallback to the item's price if any step fails
        item = Map.get(component, :item)
        fallback_price = item |> Map.get(:price) |> DecimalHelpers.to_decimal()
        D.mult(total_quantity, fallback_price)
    end
  end

  defp get_item_from_component(component) do
    case Map.get(component, :item) do
      nil -> {:error, :no_item}
      item -> {:ok, item}
    end
  end

  @spec check_for_circular_dependency(any(), MapSet.t()) :: :ok | {:error, :circular_dependency}
  defp check_for_circular_dependency(item_id, path) do
    if MapSet.member?(path, item_id) do
      {:error, :circular_dependency}
    else
      :ok
    end
  end

  defp get_active_bom_for_item(item_id, actor, authorize?) do
    case Project.get_active_bom_for_item(%{item_id: item_id},
           actor: actor,
           authorize?: authorize?
         ) do
      {:ok, bom} when not is_nil(bom) -> {:ok, bom}
      _ -> {:error, :no_active_bom}
    end
  end

  @spec calculate_nested_cost(BOM.t(), keyword(), map(), MapSet.t()) :: D.t()
  defp calculate_nested_cost(bom, opts, settings, path) do
    nested =
      do_calculate(
        bom,
        D.new(1),
        opts,
        settings,
        path
      )

    nested.unit_cost
  end

  defp waste_multiplier(component) do
    component
    |> Map.get(:waste_percent)
    |> DecimalHelpers.to_decimal()
    |> D.add(D.new(1))
  end

  @spec labor_cost([map()], D.t(), map()) :: D.t()
  defp labor_cost(labor_steps, quantity, settings) do
    base_quantity = DecimalHelpers.to_decimal(quantity)

    labor_steps
    |> Enum.sort_by(& &1.sequence)
    |> Enum.reduce(D.new(0), fn step, acc ->
      minutes = DecimalHelpers.to_decimal(step.duration_minutes)
      hourly_rate = DecimalHelpers.to_decimal(step.rate_override || settings.labor_hourly_rate)
      hours = D.div(minutes, D.new(60))
      per_run_cost = D.mult(hours, hourly_rate)

      units_per_run =
        step
        |> Map.get(:units_per_run)
        |> DecimalHelpers.to_decimal()
        |> then(fn value ->
          if D.compare(value, D.new(0)) == :gt, do: value, else: D.new(1)
        end)

      runs = D.div(base_quantity, units_per_run)
      D.add(acc, D.mult(per_run_cost, runs))
    end)
  end

  @spec overhead_cost(D.t(), D.t(), map()) :: D.t()
  defp overhead_cost(material_cost, labor_cost, settings) do
    base = D.add(material_cost, labor_cost)
    D.mult(base, settings.labor_overhead_percent)
  end

  @spec fetch_settings(keyword()) :: map()
  defp fetch_settings(opts) do
    authorize? = Keyword.get(opts, :authorize?, true)
    actor = Keyword.get(opts, :actor)

    case Settings.get_settings(actor: actor, authorize?: authorize?) do
      {:ok, nil} ->
        default_settings()

      {:ok, settings} ->
        Map.merge(default_settings(), %{
          labor_hourly_rate: DecimalHelpers.to_decimal(settings.labor_hourly_rate),
          labor_overhead_percent: DecimalHelpers.to_decimal(settings.labor_overhead_percent)
        })

      {:error, _} ->
        default_settings()
    end
  end

  defp default_settings do
    %{labor_hourly_rate: D.new(0), labor_overhead_percent: D.new(0)}
  end

  @spec maybe_track_item(MapSet.t(), any()) :: MapSet.t()
  defp maybe_track_item(path, nil), do: path
  defp maybe_track_item(path, item_id), do: MapSet.put(path, item_id)
end
