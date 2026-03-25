# lib/framework/workers/weekly_cleanup.ex
defmodule Framework.Workers.WeeklyCleanup do
  @moduledoc """
  Weekly cleanup of old data.
  """
  use Oban.Worker, queue: :default, max_attempts: 1

  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    cleanup_old_jobs()
    cleanup_old_sessions()
    cleanup_orphaned_files()

    :ok
  end

  defp cleanup_old_jobs do
    # Clean up jobs older than 90 days
    cutoff = DateTime.utc_now() |> DateTime.add(-90, :day)

    from(j in Oban.Job,
      where: j.inserted_at < ^cutoff and j.state in ["completed", "discarded"]
    )
    |> Framework.Repo.delete_all()
  end

  defp cleanup_old_sessions do
    # Your session cleanup logic
    :ok
  end

  defp cleanup_orphaned_files do
    # Your file cleanup logic
    :ok
  end
end
