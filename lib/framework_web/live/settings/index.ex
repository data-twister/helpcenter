defmodule FrameworkWeb.SettingsLive.Index do
  @moduledoc false
  use FrameworkWeb, :live_view

  alias Framework.Inventory
  alias Framework.Settings
  alias FrameworkWeb.Navigation

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:nav_sub_links, fn -> [] end)
      |> assign_new(:breadcrumbs, fn -> [] end)

    ~H"""
    <div class="mt-4 space-y-6">
      <div :if={@live_action in [:general, :index]}>
        <div class="flex flex-col gap-6 lg:flex-row">
          <div class="grow">
            <div class="rounded-md border border-gray-200 bg-white p-6">
              <.live_component
                module={FrameworkWeb.SettingsLive.FormComponent}
                id="settings-form"
                current_user={@current_user}
                title={@page_title}
                action={@live_action}
                settings={@settings}
                patch={~p"/manage/settings/general"}
              />
            </div>
          </div>

          <aside class="lg:w-64"></aside>
        </div>
      </div>

      <div :if={@live_action == :tenants}>
        <div>
          <.live_component
            module={FrameworkWeb.SettingsLive.TenantsComponent}
            id="tenants-component"
            current_user={@current_user}
            tenants={@tenants}
          />
        </div>
      </div>

      <div :if={@live_action == :api_keys}>
        <div>
          <.live_component
            module={FrameworkWeb.SettingsLive.ApiKeysComponent}
            id="api-keys-component"
            current_user={@current_user}
          />
        </div>
      </div>

      <div :if={@live_action == :calendar_feed}>
        <div>
          <.live_component
            module={FrameworkWeb.SettingsLive.CalendarFeedComponent}
            id="calendar-feed-component"
            current_user={@current_user}
          />
        </div>

        <aside class="space-y-6 lg:w-96"></aside>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    settings = Settings.get_by_id!(socket.assigns.settings.id)
    tenants = []

    socket =
      socket
      |> assign(:settings, settings)
      |> assign(:tenants, tenants)
      |> assign(:show_mapping_modal, false)
      |> assign(:selected_entity, nil)
      |> assign_new(:current_user, fn -> nil end)

    # Always configure CSV upload; harmless on other tabs and avoids missing @uploads
    socket =
      allow_upload(socket, :csv,
        accept: [".csv", "text/csv"],
        max_entries: 1
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    live_action = socket.assigns.live_action

    socket = apply_action(socket, live_action, params)

    {:noreply, Navigation.assign(socket, :settings, settings_trail(live_action))}
  end

  @impl true
  def handle_event("open_import", %{"entity" => entity}, socket) do
    {:noreply,
     socket
     |> assign(:selected_entity, entity)
     |> assign(:show_mapping_modal, true)}
  end

  def handle_event("csv_export", %{"entity" => entity}, socket) do
    {:noreply, redirect(socket, to: ~p"/manage/settings/csv/export/#{entity}")}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Settings")
  end

  defp apply_action(socket, :general, _params) do
    assign(socket, :page_title, "General Settings")
  end

  defp apply_action(socket, :api_keys, _params) do
    assign(socket, :page_title, "API Keys")
  end

  defp apply_action(socket, :calendar_feed, _params) do
    assign(socket, :page_title, "Calendar Feed")
  end

  defp apply_action(socket, :tenants, _params) do
    assign(socket, :page_title, "Tenants")
  end

  defp settings_trail(:general),
    do: [Navigation.root(:settings), Navigation.page(:settings, :general)]

  defp settings_trail(:tenants),
    do: [Navigation.root(:settings), Navigation.page(:settings, :tenants)]

  defp settings_trail(:api_keys),
    do: [Navigation.root(:settings), Navigation.page(:settings, :api_keys)]

  defp settings_trail(:calendar_feed),
    do: [Navigation.root(:settings), Navigation.page(:settings, :calendar_feed)]

  defp settings_trail(_), do: [Navigation.root(:settings)]

  @impl true
  def handle_info({FrameworkWeb.SettingsLive.FormComponent, {:saved, settings}}, socket) do
    {:noreply, assign(socket, :settings, settings)}
  end
end
