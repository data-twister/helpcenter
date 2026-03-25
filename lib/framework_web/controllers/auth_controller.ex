defmodule FrameworkWeb.AuthController do
  use FrameworkWeb, :controller
  use AshAuthentication.Phoenix.Controller

  def success(conn, activity, user, _token) do
    return_to = get_session(conn, :return_to) || ~p"/categories"

    message =
      case activity do
        {:confirm_new_user, :confirm} -> "Your email address has now been confirmed"
        {:password, :reset} -> "Your password has successfully been reset"
        _ -> "You are now signed in"
      end

    conn
    |> delete_session(:return_to)
    |> store_in_session(user)
    # If your resource has a different name, update the assign name here (i.e :current_admin)
    |> assign(:current_user, user)
    |> put_flash(:info, message)
    |> redirect(to: return_to)
  end

  def failure(conn, activity, reason) do
    message =
      case {activity, reason} do
        {_,
         %AshAuthentication.Errors.AuthenticationFailed{
           caused_by: %Ash.Error.Forbidden{
             errors: [%AshAuthentication.Errors.CannotConfirmUnconfirmedUser{}]
           }
         }} ->
          """
          You have already signed in another way, but have not confirmed your account.
          You can confirm your account using the link we sent to you, or by resetting your password.
          """

        _ ->
          "Incorrect email or password"
      end

    conn
    |> put_flash(:error, message)
    |> redirect(to: ~p"/sign-in")
  end

  def sign_out(conn, _params) do
    return_to = get_session(conn, :return_to) || ~p"/"

    conn
    |> clear_session(:framework)
    |> put_flash(:info, "You are now signed out")
    |> redirect(to: return_to)
  end


  alias Altcha.{ChallengeOptions}
  @altcha_hmac_key System.get_env("ALTCHA_HMAC_KEY") || "default-hmac-key"

  def altcha(conn, _params) do
    options = %ChallengeOptions{
      algorithm: :sha256,
      expires: DateTime.to_unix(DateTime.utc_now(), :second) + 600,
      hmac_key: @altcha_hmac_key,
      max_number: 50_000
    }

    challenge = Altcha.create_challenge(options)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(challenge))
  end
end
