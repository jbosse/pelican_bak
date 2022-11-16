defmodule PelicanWeb.StreamLive do
  use PelicanWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Coming Soon</h2>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
