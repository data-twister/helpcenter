# lib/framework/workers/cache_cleaner.ex
defmodule Framework.Workers.CacheCleaner do
  @moduledoc """
  Clears expired cache entries every 10 minutes.
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    # Your cache cleaning logic
    FrameworkWeb.Cache.clear_expired()
    :ok
  end
end
