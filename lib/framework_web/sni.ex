defmodule FrameworkWeb.SNI do
  def cert_for_host(host) do
    case Framework.Certificates.get_cert(host) do
      {:ok, %{certfile: cert, keyfile: key}} ->
        {:ok, %{certfile: cert, keyfile: key}}

      _ ->
        :error
    end
  end
end
