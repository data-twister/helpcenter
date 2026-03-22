# lib/framework/workers/email_sender.ex
defmodule Framework.Workers.EmailSender do
  use Oban.Worker, queue: :default
  import Swoosh.Email

  @impl Oban.Worker
  def perform(job) do
    params = job.args["params"]

    new()
    |> from({"Framework", "no-reply@framework.com"})
    |> to(params["to"] |> to_string())
    |> subject(params["subject"])
    |> html_body(params["body"])
    |> text_body(params["text"])
    |> Framework.Mailer.deliver!()

    :ok
  end
end
