defmodule Framework.Workers.Domain.Verification do
  use Oban.Worker, queue: "default", max_attempts: 5, unique: [period: 30]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"domain" => domain} = _args}) do
    FrameworkWeb.Origin.verify_header?(%URI{host: domain})
  end

  @doc """
  Enqueues an Oban job to do start
  """
  @spec enqueue(Map.t(), :atom) :: {:ok, Job.t()} | {:error, Job.changeset()} | {:error, term()}
  def enqueue(args, :start) do
    args
    |> new(scheduled_at: args.start_at)
    |> Framework.Oban.insert!()
  end

  def cancel(%{email: email}) do
    %Oban.Job{args: %{"email" => email}}
    |> Framework.Oban.cancel_job()

    %{email: email}
  end

  def cancel(%Oban.Job{} = job) do
    job
    |> Framework.Oban.cancel_job()

    job
  end

  def cancel(email) do
    %Oban.Job{args: %{"email" => email}}
    |> Framework.Oban.cancel_job()

    %Oban.Job{args: %{"email" => email}}
  end
end
