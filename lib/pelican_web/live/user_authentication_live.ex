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
        <% else %>
          <.input field={{f, :name}} type="hidden" />
        <% end %>
        <%= if @step == :birthdate do %>
          <.input
            field={{f, :birthdate}}
            type="date"
            label="When is your birthday?"
            placeholder="Your name"
            required
          />
        <% else %>
          <.input field={{f, :birthdate}} type="hidden" />
        <% end %>
        <%= if @step == :phone do %>
          <label>Create your account using your phone number</label>
          <.input field={{f, :country_id}} type="select" options={@country_options} required />
          <.input field={{f, :phone_number}} type="text" placeholder="Your phone" required />
        <% else %>
          <.input field={{f, :country_id}} type="hidden" />
          <.input field={{f, :phone_number}} type="hidden" />
        <% end %>
        <%= if @step == :confirmation_code do %>
          <.input
            field={{f, :confirmation_code}}
            type="text"
            label={"Enter the code we sent to #{@number}"}
            required
          />
        <% else %>
          <.input field={{f, :confirmation_code}} type="hidden" />
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
    changeset = Accounts.change_user_registration(%User{})
    step = :name

    socket =
      socket
      |> assign(:trigger_submit, false)
      |> assign(:step, step)
      |> assign(:registration, changeset)
      |> assign(:valid, false)
      |> assign(:country_options, country_options())
      |> assign(:continue_button_text, "Continue")
      |> assign(:error, "")

    {:ok, socket}
  end


  def handle_event("validate", %{"user" => user_params}, %{assigns: %{step: :confirmation_code}} = socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)

    socket = socket
    |> assign(:registration, changeset)
    |> assign(:trigger_submit, user_params["confirmation_code"] |> String.length() == 6)

    {:noreply, socket}
  end

  def handle_event("validate", %{"user" => user_params}, %{assigns: %{step: step}} = socket) do
    valid = case step do
      :name -> user_params["name"] != ""
      :birthdate ->
        case Date.from_iso8601(user_params["birthdate"]) do
          {:ok, _} -> user_params["birthdate"] != ""
          _ -> false
        end
      :phone ->
          user_params["country_id"] != "" && user_params["phone_number"] != ""
          country = Countries.get_country!(user_params["country_id"])
          clean_number = String.replace(user_params["phone_number"], ~r/[^0-9]/, "")
          clean_phone_number = "+#{country.code}#{clean_number}"
          %{valid: valid} = Libphonenumber.mobile_phone_number_info(clean_phone_number)
          valid
    end
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, socket |> assign(:valid, valid) |> assign(:registration, changeset)}
  end

  def handle_event("next", %{"user" => user_params}, %{assigns: %{step: :confirmation_code}} = socket) do
    socket = send_code(user_params, socket)
    {:noreply, socket}
  end

  def handle_event("next", %{"user" => user_params}, %{assigns: %{step: :phone}} = socket) do
    socket = send_code(user_params, socket) |> assign(:step, :confirmation_code)
    {:noreply, socket}
  end

  def handle_event("next", %{"user" => user_params}, %{assigns: %{step: step}} = socket) do
    step =  case step do
      :name -> :birthdate
      :birthdate -> :phone
      :phone -> :confirmation_code
    end

    changeset = Accounts.change_user_registration(%User{}, user_params)

    socket =
      socket
      |> assign(:step, step)
      |> assign(:registration, changeset)
      |> assign(:valid, false)

    {:noreply, socket}
  end

  def handle_event("next", %{"user" => user_params}, %{assigns: %{step: :birthdate}} = socket) do
    step = :phone
    changeset = Accounts.change_user_registration(%User{}, user_params)

    socket =
      socket
      |> assign(:step, step)
      |> assign(:registration, changeset)
      |> assign(:valid, false)

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
    |> Enum.map(fn c -> {"#{c.flag} +#{c.code} #{c.name}", "#{c.id}"} end)
  end

  defp send_code(user_params, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)

    socket = case Pelican.Messages.send_code(user_params) do
      {:ok, number_display, code } -> socket |> assign(number: number_display, code: code)
      {:error, %{"message" => message}, _} -> socket |> assign(:error, message)
    end

    :timer.send_interval(1000, self(), :tick)

    socket
      |> assign(:registration, changeset)
      |> assign(:ticks, 60)
      |> assign(:continue_button_text, "Resend in 60s")
      |> assign(:valid, false)
  end
end
