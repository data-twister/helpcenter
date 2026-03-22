# test/framework/accounts/authorized_test.exs
defmodule Framework.Accounts.AuthorizedTest do
  use FrameworkWeb.ConnCase, async: false

  describe "Authorized Check" do
    test "Tenant owner is always authorized" do
      owner = create_user()

      assert Ash.can?({Framework.KnowledgeBase.Category, :create}, owner)
      assert Ash.can?({Framework.KnowledgeBase.Category, :read}, owner)
      assert Ash.can?({Framework.KnowledgeBase.Category, :update}, owner)
      assert Ash.can?({Framework.KnowledgeBase.Category, :destroy}, owner)
    end

    test "Nil actors are not authorized" do
      user = nil

      refute Ash.can?({Framework.KnowledgeBase.Category, :create}, user)
      refute Ash.can?({Framework.KnowledgeBase.Category, :read}, user)
      refute Ash.can?({Framework.KnowledgeBase.Category, :update}, user)
      refute Ash.can?({Framework.KnowledgeBase.Category, :destroy}, user)
    end

    test "Non tenant owner are allowed if they have permission" do
      owner = create_user()

      user =
        Ash.Seed.seed!(Framework.Accounts.User, %{
          email: "new_user@example.com",
          current_tenant: owner.current_tenant
        })

      tenant = user.current_tenant

      # Add user to the tenant
      tenant = Ash.read_first!(Framework.Accounts.Tenant)
      user_tenant_attrs = %{user_id: user.id, tenant_id: tenant.id}
      _user_tenant = Ash.Seed.seed!(Framework.Accounts.UserTenant, user_tenant_attrs)

      # Add Access group
      group =
        Ash.Seed.seed!(
          Framework.Accounts.Group,
          %{name: "Accountant", description: "Finance accountant"},
          tenant: tenant,
          authorize?: false
        )

      # Add group permission
      Ash.Seed.seed!(
        Framework.Accounts.GroupPermission,
        %{group_id: group.id, action: :read, resource: Framework.KnowledgeBase.Category},
        tenant: tenant,
        authorize?: false
      )

      # Add user to the group
      Ash.Seed.seed!(
        Framework.Accounts.UserGroup,
        %{user_id: user.id, group_id: group.id},
        tenant: tenant,
        authorize?: false
      )

      # # Confirm that this user is not authorized to create but authorized to read
      assert Ash.can?({Framework.KnowledgeBase.Category, :read}, user)
      refute Ash.can?({Framework.KnowledgeBase.Category, :create}, user)
      refute Ash.can?({Framework.KnowledgeBase.Category, :update}, user)
      refute Ash.can?({Framework.KnowledgeBase.Category, :destroy}, user)
    end
  end
end
