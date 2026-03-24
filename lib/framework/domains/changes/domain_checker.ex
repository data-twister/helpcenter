defmodule Framework.Domains.Changes.DomainCheck do
  use Ash.Resource.Change

  def change(changeset, _tenant, _context) do
    Ash.Changeset.after_action(changeset, &run/2)
  end

  defp run(_changeset, domain) do
    Framework.Workers.Domain.Verification.enqueue(%{domain: domain.host, start_at: 60})

    {:ok, domain}
  end
end
