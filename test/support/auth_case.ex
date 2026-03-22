# test/support/auth_case.ex
defmodule AuthCase do
  require Ash.Query

  def login(conn, user) do
    case AshAuthentication.Jwt.token_for_user(user, %{}, domain: Framework.Accounts) do
      {:ok, token, _claims} ->
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> Plug.Conn.put_session(:user_token, token)

      {:error, reason} ->
        raise "Failed to generate token: #{inspect(reason)}"
    end
  end

  def get_user() do
    case Ash.read_first(Framework.Accounts.User) do
      {:ok, nil} -> create_user()
      {:ok, user} -> user
    end
  end

  def create_user() do
    # Create a user and the person tenant automatically.
    # The person tenant will be the tenant for the query
    count = System.unique_integer([:monotonic, :positive])

    tenant_domain = "tenant_#{count}"
    user_params = %{email: "john.tester_#{count}@example.com", current_tenant: tenant_domain}
    user = Ash.Seed.seed!(Framework.Accounts.User, user_params)

    # Create a new tenant for the user
    tenant_attrs = %{name: "Tenant #{count}", domain: tenant_domain, owner_user_id: user.id}
    tenant = Ash.Seed.seed!(Framework.Accounts.Tenant, tenant_attrs)

    Ash.Seed.seed!(Framework.Accounts.UserTenant, %{user_id: user.id, tenant_id: tenant.id})

    # Return created tenant
    user
  end

  def get_group(user \\ nil) do
    actor = user || create_user()

    case Ash.read_first(Framework.Accounts.Group, actor: actor) do
      {:ok, nil} -> create_groups(actor) |> Enum.at(0)
      {:ok, group} -> group
    end
  end

  def get_groups(user \\ nil) do
    actor = user || create_user()

    case Ash.read(Framework.Accounts.Group, actor: actor) do
      {:ok, []} -> create_groups(actor)
      {:ok, groups} -> groups
    end
  end

  def create_groups(user \\ nil) do
    actor = user || create_user()

    group_attrs = [
      %{name: "Accountant", description: "Finance accountant"},
      %{name: "Manager", description: "Tenant manager"},
      %{name: "Developer", description: "Software developer"},
      %{name: "Admin", description: "System administrator"},
      %{name: "HR", description: "Human resources specialist"}
    ]

    Ash.Seed.seed!(Framework.Accounts.Group, group_attrs, tenant: actor.current_tenant)
  end
end
