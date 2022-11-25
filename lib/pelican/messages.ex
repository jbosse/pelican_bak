defmodule Pelican.Messages do
  alias Pelican.Countries

  def send_message(options \\ []) do
    defaults = [to: nil, from: Application.get_env(:ex_twilio, :twilio_phone_number), body: nil]
    options = Keyword.merge(defaults, options) |> Enum.into(%{})
    %{to: to, from: from, body: body} = options

    if Application.get_env(:pelican, :enable_twillio) do
      ExTwilio.Message.create(to: to, from: from, body: body) |> IO.inspect()
    else
      {:ok, IO.inspect(%{to: to, from: from, body: body})}
    end
  end

  def send_code(%{"country_id" => country_id, "phone_number" => phone_number} = user_attrs) do
    country = Countries.get_country!(country_id)
    clean_phone_number = String.replace(phone_number, ~r/[^0-9]/, "")
    clean_number = "+#{country.code}#{clean_phone_number}"
    number_display = "+#{country.code} #{phone_number}"
    code = Enum.random(100_000..999_999)
    clean_attrs = %{user_attrs | "phone_number" => clean_phone_number, "confirmation_code" => "#{code}"}

    case Pelican.Accounts.get_user_by_number(country_id, clean_phone_number) do
      nil ->
        IO.puts("NEW USER")
        Pelican.Accounts.register_user(clean_attrs)
      user ->
        IO.puts("UPDATE USER")
        IO.inspect(clean_attrs)
        Pelican.Accounts.update_user(user, clean_attrs)
    end

    body = "#{code} is your verification code for Pelican."

    case send_message(to: clean_number, body: body) do
      {:ok, _} -> {:ok, number_display, code}
      result -> result
    end
  end
end
