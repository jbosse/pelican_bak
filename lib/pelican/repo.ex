defmodule Pelican.Repo do
  use Ecto.Repo,
    otp_app: :pelican,
    adapter: Ecto.Adapters.Postgres
end
