# /home/kamaro/elixir/framework/lib/framework.ex
defmodule Framework do
  @moduledoc """
  Framework keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defdelegate permissions(), to: Framework.Accounts.Permission
end
