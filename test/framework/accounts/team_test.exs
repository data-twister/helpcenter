defmodule Framework.Accounts.TenantTest do
  use FrameworkWeb.ConnCase, async: false
  require Ash.Query

  describe "Tenant tests" do
    test "User tenant can be created" do
      user = create_user()

      # Create a new tenant for the user
      tenant_count = Ash.count!(Framework.Accounts.Tenant)

      tenant_attrs = %{
        name: "Tenant #{tenant_count}",
        domain: "tenant_#{tenant_count}",
        owner_user_id: user.id
      }

      {:ok, tenant} = Ash.create(Framework.Accounts.Tenant, tenant_attrs)

      # New tenant should be stored successfully.
      assert Framework.Accounts.Tenant
             |> Ash.Query.filter(domain == ^tenant.domain)
             |> Ash.Query.filter(owner_user_id == ^tenant.owner_user_id)
             |> Ash.exists?()

      # New tenant should be set as the current tenant on the owner
      assert Framework.Accounts.User
             |> Ash.Query.filter(id == ^user.id)
             |> Ash.Query.filter(current_tenant == ^tenant.domain)
             #  User resource has special policies for authorizations. We are skipping authorization by setting it to false
             |> Ash.exists?(authorize?: false)

      # New tenant should be added to the tenants list of the owner
      assert Framework.Accounts.User
             |> Ash.Query.filter(id == ^user.id)
             |> Ash.Query.filter(tenants.id == ^tenant.id)
             |> Ash.exists?(authorize?: false)
    end
  end
end
