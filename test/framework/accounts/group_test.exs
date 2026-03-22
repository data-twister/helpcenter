# test/framework/accounts/group_test.exs
defmodule Framework.Accounts.GroupTest do
  use FrameworkWeb.ConnCase, async: false
  require Ash.Query

  describe "Access Group Tests" do
    test "Groups can be added to a tenant" do
      # Groups are specific to a tenant. So we need a tenant for group
      user = create_user()

      group_attrs = %{
        name: "Accountants",
        description: "Can manage billing in the system"
      }

      {:ok, _group} =
        Ash.create(
          Framework.Accounts.Group,
          group_attrs,
          actor: user,
          load: [:permissions],
          authorize?: false
        )

      assert Framework.Accounts.Group
             |> Ash.Query.filter(name == ^group_attrs.name)
             |> Ash.Query.filter(description == ^group_attrs.description)
             |> Ash.exists?(actor: user)
    end
  end
end
