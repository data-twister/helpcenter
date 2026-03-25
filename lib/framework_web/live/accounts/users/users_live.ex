# lib/framework_web/live/accounts/users/users_live.ex
defmodule FrameworkWeb.Accounts.Users.UsersLive do
  use FrameworkWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <FrameworkWeb.Accounts.Users.UserInvitationsLive.InviteNewUserForm.form actor={@current_user} />

    <%!-- User list --%>
    <Cinder.Table.table query={get_query(@current_user)} page_size={10} id="users-table">
      <:col :let={row} label="Email" field="email" filter sort>{row.email}</:col>
      <:col :let={row} label="Domain"></:col>
      <:col :let={row} label="Tenant">{Phoenix.Naming.humanize(row.current_tenant)}</:col>
    </Cinder.Table.table>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, "Users")
    |> ok()
  end

  defp get_query(current_user) do
    require Ash.Query

    Framework.Accounts.User
    |> Ash.Query.filter(tenants.prefix == ^current_user.current_tenant)
    |> Ash.Query.for_read(:read, %{}, authorize?: false)
  end
end
