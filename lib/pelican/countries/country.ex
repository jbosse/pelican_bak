defmodule Pelican.Countries.Country do
  use Ecto.Schema
  import Ecto.Changeset

  schema "countries" do
    field :code, :string
    field :flag, :string
    field :name, :string
    field :notification_offset, :integer

    timestamps()
  end

  @doc false
  def changeset(country, attrs) do
    country
    |> cast(attrs, [:name, :code, :notification_offset, :flag])
    |> validate_required([:name, :code, :notification_offset, :flag])
  end
end
