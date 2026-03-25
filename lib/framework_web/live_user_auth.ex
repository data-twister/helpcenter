defmodule FrameworkWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  import Phoenix.Component
  use FrameworkWeb, :verified_routes
  use FrameworkWeb, :live_view

  def on_mount(:live_user_optional, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:live_user_required, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: ~p"/sign-in")}
    end
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:halt, redirect(socket, to: ~p"/")}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:domain, _params, _session, socket) do
    domain = extract_domain(socket)
    {:cont, assign(socket, :domain, domain)}
  end

  defp extract_domain(socket) do
    forwarded =
      get_connect_info(socket, :x_headers)
      |> Enum.find_value(fn
        {"x-forwarded-host", h} -> h
        _ -> nil
      end)

    uri = get_connect_info(socket, :uri)

    forwarded || (uri && uri.host)
  end
end
