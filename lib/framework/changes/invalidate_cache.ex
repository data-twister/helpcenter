defmodule Framework.Changes.InvalidateCache do
  @moduledoc """
  Invalidates resource cache after write operations.
  """
  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, result ->
      tenant = changeset.tenant
      resource = changeset.resource

      # Invalidate entire resource cache for this tenant
      FrameworkWeb.Cache.invalidate_resource(resource, tenant: tenant)

      {:ok, result}
    end)
  end
end
