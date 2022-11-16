defmodule PelicanWeb.UserAuthenticationLive do
  use PelicanWeb, :live_view

  alias Pelican.Countries
  alias Pelican.Accounts
  alias Pelican.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.simple_form
        :let={f}
        id="registration_form"
        for={@registration}
        phx-submit="next"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
        as={:user}
      >
        <%= if @error != "" do %>
          <h2 class="text-red"><%= @error %></h2>
        <% end %>
        <%= if @step == :name do %>
          <.input
            field={{f, :name}}
            type="text"
            label="What is your name?"
            placeholder="Your name"
            required
          />
        <% end %>
        <%= if @step == :birthdate do %>
          <.input
            field={{f, :birthdate}}
            type="date"
            label="When is your birthday?"
            placeholder="Your name"
            required
          />
        <% end %>
        <%= if @step == :phone do %>
          <label>Create your account using your phone number</label>
          <.input field={{f, :country_id}} type="select" options={country_options()} required />
          <.input field={{f, :phone_number}} type="text" placeholder="Your phone" required />
        <% end %>
        <%= if @step == :confirmation_code do %>
          <.input
            field={{f, :confirmation_code}}
            type="text"
            label={"Enter the code we sent to #{@number}"}
            required
          />
        <% end %>

        <:actions>
          <.button phx-disable-with="..." class="w-full disabled:bg-zinc-300" disabled={!@valid}>
            <%= @continue_button_text %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = %User{}
    registration = Accounts.change_user_registration(user)
    step = :name

    socket =
      socket
      |> assign(trigger_submit: false)
      |> assign(user: user)
      |> assign(step: step)
      |> assign(registration: registration)
      |> assign(:valid, false)
      |> assign(:continue_button_text, "Continue")
      |> assign(:error, "")

    {:ok, socket}
  end

  def handle_event(
        "validate",
        %{"user" => %{"name" => name}},
        %{assigns: %{step: :name}} = socket
      ) do
    valid = name != ""
    socket = socket |> assign(:valid, valid)
    {:noreply, socket}
  end

  def handle_event(
        "validate",
        %{"user" => %{"birthdate" => birthdate}},
        %{assigns: %{step: :birthdate}} = socket
      ) do
    valid = birthdate != ""
    socket = socket |> assign(:valid, valid)
    {:noreply, socket}
  end

  def handle_event(
        "validate",
        %{"user" => %{"country_id" => country_id, "phone_number" => phone_number}},
        %{assigns: %{step: :phone}} = socket
      ) do
    user = socket.assigns.user
    country = Countries.get_country!(country_id)
    user = %User{user | country_id: country.id}
    registration = Accounts.change_user_registration(user)
    number = "+#{country.code}#{phone_number}"
    %{valid: valid} = Libphonenumber.mobile_phone_number_info(number)
    socket = socket |> assign(:registration, registration) |> assign(:valid, valid)
    {:noreply, socket}
  end

  def handle_event(
        "validate",
        %{"user" => %{"confirmation_code" => confirmation_code}},
        %{assigns: %{step: :confirmation_code}} = socket
      ) do
    socket =
      if confirmation_code |> String.length() == 6 do
        if confirmation_code == "123456" do
          socket |> redirect(to: ~p"/stream")
        else
          socket |> assign(:error, "Invalid code")
        end
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("next", %{"user" => %{"name" => name}}, socket) do
    user = socket.assigns.user
    user = %User{user | name: name}
    registration = Accounts.change_user_registration(user)
    step = :birthdate

    socket =
      socket
      |> assign(trigger_submit: false)
      |> assign(user: user)
      |> assign(step: step)
      |> assign(registration: registration)
      |> assign(:valid, false)

    {:noreply, socket}
  end

  def handle_event("next", %{"user" => %{"birthdate" => birthdate}}, socket) do
    user = socket.assigns.user
    user = %User{user | birthdate: birthdate}
    registration = Accounts.change_user_registration(user)
    step = :phone

    socket =
      socket
      |> assign(trigger_submit: false)
      |> assign(user: user)
      |> assign(step: step)
      |> assign(registration: registration)
      |> assign(:valid, false)

    {:noreply, socket}
  end

  def handle_event(
        "next",
        %{"user" => %{"country_id" => country_id, "phone_number" => phone_number}},
        socket
      ) do
    user = socket.assigns.user
    user = %User{user | country_id: country_id, phone_number: phone_number}
    registration = Accounts.change_user_registration(user)
    step = :confirmation_code

    country = Countries.get_country!(country_id)
    number = "+#{country.code}#{phone_number}"

    body = "123456 is your verification code for Pelican."

    # _message =
    #   ExTwilio.Message.create(to: number, from: "+14782495438", body: body) |> IO.inspect()

    :timer.send_interval(1000, self(), :tick)

    socket =
      socket
      |> assign(trigger_submit: false)
      |> assign(user: user)
      |> assign(step: step)
      |> assign(registration: registration)
      |> assign(:valid, false)
      |> assign(:number, number)
      |> assign(:ticks, 60)
      |> assign(:continue_button_text, "Resend in 60s")

    {:noreply, socket}
  end

  def handle_info(:tick, %{assigns: %{ticks: 0}} = socket) do
    socket =
      socket
      |> assign(:ticks, 0)
      |> assign(:valid, true)
      |> assign(:continue_button_text, "Resend")

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    ticks = socket.assigns.ticks - 1

    socket =
      socket
      |> assign(:ticks, ticks)
      |> assign(:continue_button_text, "Resend in #{ticks}s")

    {:noreply, socket}
  end

  defp country_options do
    Pelican.Countries.list_countries()
    |> Enum.map(fn c -> {"#{c.flag} +#{c.code} #{c.name}", c.id} end)
  end
end
