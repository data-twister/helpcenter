# lib/framework_web/live/accounts/users/users_live_test.exs
defmodule FrameworkWeb.Accounts.Users.UsersLiveTest do
  use FrameworkWeb.ConnCase

  describe "UsersLive" do
    test "renders the users page", %{conn: conn} do
      user = create_user()

      conn =
        conn
        |> login(user)
        |> get(~p"/accounts/users")

      assert html_response(conn, 200) =~ "Users"
      assert html_response(conn, 200) =~ "Email"
      assert html_response(conn, 200) =~ "Tenant"
    end
  end
end
