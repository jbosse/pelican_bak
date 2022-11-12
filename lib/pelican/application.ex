defmodule Pelican.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PelicanWeb.Telemetry,
      # Start the Ecto repository
      Pelican.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Pelican.PubSub},
      # Start Finch
      {Finch, name: Pelican.Finch},
      # Start the Endpoint (http/https)
      PelicanWeb.Endpoint
      # Start a worker by calling: Pelican.Worker.start_link(arg)
      # {Pelican.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pelican.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PelicanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
