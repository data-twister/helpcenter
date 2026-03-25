defmodule FrameworkWeb.Cache do
  @moduledoc """
  Tenant-aware caching layer for Ash resources using ETS.
  Ensures cache isolation between tenants to prevent data leakage.
  Integrates with Ash's data layer and multitenancy strategy.
  """

  @table_name :framework_cache
  @default_ttl :timer.minutes(5)

  @doc """
  Initializes the ETS cache table. Call this in your application supervision tree.
  """
  def init do
    :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])
  end

  @doc """
  Gets or fetches an Ash resource with tenant-aware caching.

  ## Examples

      # Read single resource
      FrameworkWeb.Cache.get_or_fetch(
        Framework.Project.Item,
        :read,
        %{id: item_id},
        tenant: tenant,
        ttl: :timer.minutes(10)
      )

      # List resources
      FrameworkWeb.Cache.get_or_fetch(
        Framework.Project.Item,
        :list,
        %{status: [:active]},
        tenant: tenant
      )
  """
  def get_or_fetch(resource, action, params \\ %{}, opts \\ []) do
    key = build_ash_cache_key(resource, action, params, opts)

    case :ets.lookup(@table_name, key) do
      [{^key, {value, expiry}}] ->
        if :erlang.monotonic_time(:millisecond) < expiry do
          value
        else
          :ets.delete(@table_name, key)
          fetch_and_store_ash(key, resource, action, params, opts)
        end

      [] ->
        fetch_and_store_ash(key, resource, action, params, opts)
    end
  end

  @doc """
  Wraps Ash.read! with caching.

  ## Examples

      FrameworkWeb.Cache.read!(
        Framework.Project.Item,
        tenant: tenant,
        ttl: :timer.minutes(5)
      )
  """
  def read!(resource, opts \\ []) do
    action = Keyword.get(opts, :action, :read)
    params = Keyword.get(opts, :params, %{})
    get_or_fetch(resource, action, params, opts)
  end

  @doc """
  Wraps Ash.get! with caching for single resource fetch by ID.

  ## Examples

      FrameworkWeb.Cache.get!(
        Framework.Project.Item,
        item_id,
        tenant: tenant
      )
  """
  def get!(resource, id, opts \\ []) do
    action = Keyword.get(opts, :action, :read)
    params = Map.put(%{}, :id, id)

    get_or_fetch(resource, action, params, opts)
  end

  @doc """
  Invalidates cache for a specific Ash resource and tenant.
  Call this after create, update, or delete operations.

  ## Examples

      # After create/update/delete
      FrameworkWeb.Cache.invalidate_resource(
        Framework.Project.Item,
        tenant: tenant
      )
  """
  def invalidate_resource(resource, opts \\ []) do
    tenant = get_tenant_from_opts(opts)
    resource_name = inspect(resource)

    prefix =
      case tenant do
        nil -> resource_name
        t -> "#{tenant_id(t)}:#{resource_name}"
      end

    pattern = {:"$1", :"$2"}

    :ets.match(@table_name, pattern)
    |> Enum.each(fn [key, _value] ->
      if String.starts_with?(to_string(key), prefix) do
        :ets.delete(@table_name, key)
      end
    end)

    :ok
  end

  @doc """
  Invalidates all cache entries for a specific tenant.
  """
  def invalidate_tenant(tenant) do
    t_id = tenant_id(tenant)
    pattern = {:"$1", :"$2"}

    :ets.match(@table_name, pattern)
    |> Enum.each(fn [key, _value] ->
      if String.starts_with?(to_string(key), "#{t_id}:") do
        :ets.delete(@table_name, key)
      end
    end)

    :ok
  end

  @doc """
  Invalidates cache for a specific resource record by ID.
  Useful for targeted invalidation after updating a single record.
  """
  def invalidate_record(resource, id, opts \\ []) do
    tenant = get_tenant_from_opts(opts)
    resource_name = inspect(resource)

    # Build pattern to match this specific record
    id_str = to_string(id)

    pattern = {:"$1", :"$2"}

    :ets.match(@table_name, pattern)
    |> Enum.each(fn [key, _value] ->
      key_str = to_string(key)

      matches_tenant =
        case tenant do
          nil -> not String.contains?(key_str, ":")
          t -> String.starts_with?(key_str, "#{tenant_id(t)}:")
        end

      if matches_tenant and String.contains?(key_str, resource_name) and
           String.contains?(key_str, id_str) do
        :ets.delete(@table_name, key)
      end
    end)

    :ok
  end

  @doc """
  Clears all cache entries. Use with caution.
  """
  def clear_all do
    :ets.delete_all_objects(@table_name)
    :ok
  end

  @doc """
  Gets cache statistics.
  """
  def stats do
    info = :ets.info(@table_name)

    %{
      size: Keyword.get(info, :size, 0),
      memory_bytes: Keyword.get(info, :memory, 0) * :erlang.system_info(:wordsize),
      table_name: @table_name
    }
  end

  # Private functions

  defp build_ash_cache_key(resource, action, params, opts) do
    tenant = get_tenant_from_opts(opts)
    resource_name = inspect(resource)
    action_name = to_string(action)
    params_hash = hash_params(params)

    base_key = "#{resource_name}:#{action_name}:#{params_hash}"

    case tenant do
      nil -> base_key
      t -> "#{tenant_id(t)}:#{base_key}"
    end
  end

  defp fetch_and_store_ash(key, resource, action, params, opts) do
    tenant = get_tenant_from_opts(opts)

    # Build Ash query/changeset based on action type
    result =
      case action do
        :read ->
          query =
            resource
            |> Ash.Query.for_read(action, params)
            |> maybe_set_tenant(tenant)

          Ash.read!(query)

        :list ->
          query =
            resource
            |> Ash.Query.for_read(action, params)
            |> maybe_set_tenant(tenant)

          Ash.read!(query)

        _ ->
          query =
            resource
            |> Ash.Query.for_read(action, params)
            |> maybe_set_tenant(tenant)

          case Ash.read(query) do
            {:ok, results} -> results
            {:error, _} -> []
          end
      end

    ttl = Keyword.get(opts, :ttl, @default_ttl)
    expiry = :erlang.monotonic_time(:millisecond) + ttl

    :ets.insert(@table_name, {key, {result, expiry}})
    result
  end

  defp maybe_set_tenant(query, nil), do: query

  defp maybe_set_tenant(query, tenant) do
    Ash.Query.set_tenant(query, tenant_id(tenant))
  end

  defp get_tenant_from_opts(opts) do
    Keyword.get(opts, :tenant)
  end

  defp tenant_id(tenant) when is_binary(tenant), do: tenant
  defp tenant_id(%{id: id}), do: id

  defp tenant_id(tenant) when is_map(tenant) do
    Map.get(tenant, :id) || Map.get(tenant, "id")
  end

  defp hash_params(params) when params == %{}, do: "empty"

  defp hash_params(params) do
    :crypto.hash(:md5, inspect(params))
    |> Base.encode16()
    |> String.slice(0..7)
  end
end
