# lib/framework/accounts.ex
defmodule Framework.Accounts do
  use Ash.Domain, otp_app: :framework

  resources do
    resource Framework.Accounts.Tenant do
      define :list_origins, action: :list_origins
    end

    resource Framework.Accounts.ApiKey do
      define :revoke_api_key, action: :revoke
    end

    resource Framework.Accounts.User
    resource Framework.Accounts.Group
    resource Framework.Accounts.UserTenant
    resource Framework.Accounts.UserGroup
    resource Framework.Accounts.GroupPermission

    resource Framework.Accounts.Token
    resource Framework.Accounts.Invitation

    resource Framework.Accounts.UserNotification do
      define :notify, action: :create
    end
  end
end
