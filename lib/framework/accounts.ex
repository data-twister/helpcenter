# lib/framework/accounts.ex
defmodule Framework.Accounts do
  use Ash.Domain, otp_app: :framework

  resources do
    resource Framework.Accounts.Tenant
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
