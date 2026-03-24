defmodule Framework.Project.Changes.AssignBOMVersion do
  @moduledoc false

  use Ash.Resource.Change

  alias Ash.Changeset
  alias Ash.Query
  alias Framework.Project.BOM

  @impl true
  def change(changeset, _opts, _context) do
    case Changeset.get_attribute(changeset, :item_id) do
      item_id when not is_nil(item_id) -> maybe_assign_version(changeset, item_id)
      _ -> changeset
    end
  end

  defp maybe_assign_version(changeset, item_id) do
    with nil <- Changeset.get_attribute(changeset, :version),
         {:ok, next_version} <- compute_next_version(item_id, changeset.context[:actor]) do
      Changeset.force_change_attribute(changeset, :version, next_version)
    else
      _ -> changeset
    end
  end

  defp compute_next_version(item_id, actor) do
    case latest_version(item_id, actor) do
      {:ok, version} -> {:ok, version + 1}
      :not_found -> {:ok, 1}
      {:error, reason} -> {:error, reason}
    end
  end

  defp latest_version(item_id, actor) do
    case BOM
         |> Query.new()
         |> Query.filter(item_id == ^item_id)
         |> Query.sort(version: :desc)
         |> Query.limit(1)
         |> Ash.read_one(actor: actor, authorize?: false) do
      {:ok, %{version: version}} -> {:ok, version}
      {:ok, nil} -> :not_found
      {:error, reason} -> {:error, reason}
    end
  end
end
