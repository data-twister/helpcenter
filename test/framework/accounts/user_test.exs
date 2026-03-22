defmodule Framework.Accounts.UserTest do
  use FrameworkWeb.ConnCase, async: false
  require Ash.Query

  describe "User tests:" do
    test "User creation - creates personal tenant automatically" do
      # Create a new user
      user_params = %{
        email: "john.tester@example.com",
        password: "12345678",
        password_confirmation: "12345678"
      }

      user =
        Ash.create!(
          Framework.Accounts.User,
          user_params,
          action: :register_with_password,
          authorize?: false
        )

      # Confirm that the new user has a personal tenant created for them automatically
      refute Framework.Accounts.User
             |> Ash.Query.filter(id == ^user.id)
             |> Ash.Query.load(:groups)
             |> Ash.Query.filter(email == ^user_params.email)
             |> Ash.Query.filter(is_nil(current_tenant))
             |> Ash.exists?(actor: user, authorize?: false)
    end
  end
end
