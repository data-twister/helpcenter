defmodule Framework.Secrets do
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], Framework.Accounts.User, _opts) do
    Application.fetch_env(:framework, :token_signing_secret)
  end
end
