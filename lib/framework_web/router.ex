defmodule FrameworkWeb.Router do
  use FrameworkWeb, :router

  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FrameworkWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
    plug FrameworkWeb.Plugs.SetTenant
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  pipeline :user do
    plug :put_root_layout, html: {FrameworkWeb.Layouts, :user}
    plug :default_assigns
  end

  scope "/", FrameworkWeb do
    pipe_through :browser

    #    FrameworkWeb.live_session_with_domain :authenticated_routes,
    #      on_mount: [
    #       {FrameworkWeb.LiveUserAuth, :live_user_required},
    #    {FrameworkWeb.DomainOnMount, :default}
    #      ] do
    ash_authentication_live_session :authenticated_routes,
      on_mount: [
        {FrameworkWeb.LiveUserAuth, :live_user_required},
        {FrameworkWeb.DomainOnMount, :default}
      ] do
      # in each liveview, add one of the following at the top of the module:
      #
      # If an authenticated user must be present:
      # on_mount {FrameworkWeb.LiveUserAuth, :live_user_required}
      #
      # If an authenticated user *may* be present:
      # on_mount {FrameworkWeb.LiveUserAuth, :live_user_optional}
      #
      # If an authenticated user must *not* be present:
      # on_mount {FrameworkWeb.LiveUserAuth, :live_no_user}

      live "/grok", GrokLayoutLive

      scope "/manage" do
        live "/settings", SettingsLive.Index, :index
      end

      scope "/categories" do
        live "/", CategoriesLive
        live "/create", CreateCategoryLive
        live "/:category_id", EditCategoryLive
      end

      # lib/framework_web/router.ex
      scope "/accounts", Accounts do
        scope "/users", Users do
          live "/", UsersLive
          live "/invitations", UserInvitationsLive
        end

        scope "/groups", Groups do
          live "/", GroupsLive
          live "/:group_id/permissions", GroupPermissionsLive
        end
      end
    end
  end

  scope "/", FrameworkWeb do
    pipe_through :browser

    auth_routes AuthController, Framework.Accounts.User, path: "/auth"
    sign_out_route AuthController

    # Remove these if you'd like to use your own authentication views
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [{FrameworkWeb.LiveUserAuth, :live_no_user}],
                  overrides: [
                    FrameworkWeb.AuthOverrides,
                    AshAuthentication.Phoenix.Overrides.Default
                  ]

    # Remove this if you do not want to use the reset password feature
    reset_route auth_routes_prefix: "/auth",
                overrides: [
                  FrameworkWeb.AuthOverrides,
                  AshAuthentication.Phoenix.Overrides.Default
                ]
  end

  scope "/", FrameworkWeb do
    pipe_through :browser

    get "/", PageController, :home

    get "/accounts/users/invitations/:tenant/:token/accept",
        TenantInvitationAcceptanceController,
        :accept

    get "/accounts/users/invitations/:tenant/:token/reject",
        TenantInvitationAcceptanceController,
        :reject
  end

  # Other scopes may use custom stacks.
  # scope "/api", FrameworkWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:framework, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard",
        metrics: FrameworkWeb.Telemetry,
        additional_pages: [
          oban: Oban.LiveDashboard
        ]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
