defmodule FrameworkWeb.Origin do
  @moduledoc """
  This module is responsible for verifying the origin of the request from the configured tenants
    Verification is done as part of the check origins endpoint module: config/runtime.exs
  """

  use Memoize

  require Logger

  def verify_header?(%URI{} = uri, code) do
    result =
      case verify_origin?(uri) do
        true -> :ok
        false -> :inet_res.lookup(uri.host, :in, :txt) |> Enum.member?(code)
      end

    case result do
      true ->
        domain = Framework.Domains.lookup_by_auth_code(code)
        Framework.Accounts.add_domain_via_code(domain)

      false ->
        domain = Framework.Domains.lookup_by_auth_code(code)
        Framework.Domains.update(domain, %{status: "failed"})
        :error

      _ ->
        :ok
    end
  end

  def verify_origin?(%URI{} = uri) do
    uri.host in origins()
  end

  defmemop origins(), expires_in: 60 * 1000 do
    Framework.Tenants.list_origins()
    |> Enum.map(fn x -> x.domain end)
    |> Enum.reject(fn x -> is_nil(x) || String.length(x) < 5 end)
  end
end
