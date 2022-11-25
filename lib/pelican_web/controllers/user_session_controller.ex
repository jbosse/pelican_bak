defmodule PelicanWeb.UserSessionController do
  use PelicanWeb, :controller

  alias Pelican.Accounts
  alias PelicanWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account signin successful!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{
      "country_id" => country_id,
      "phone_number" => phone_number,
      "confirmation_code" => confirmation_code
    } = user_params

    clean_number = String.replace(phone_number, ~r/[^0-9]/, "")
    clean_user_params = %{user_params| "phone_number" => clean_number}

    if user = Accounts.get_user_by_phone_and_code(country_id, clean_number, confirmation_code) do
      conn
      |> put_flash(:info, info)
      |> put_session(:user_return_to, ~p"/stream")
      |> UserAuth.log_in_user(user, clean_user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid code")
      |> redirect(to: ~p"/")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
