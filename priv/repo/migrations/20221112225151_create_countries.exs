defmodule Pelican.Repo.Migrations.CreateCountries do
  use Ecto.Migration

  def change do
    create table(:countries) do
      add :name, :string
      add :code, :string
      add :notification_offset, :integer
      add :flag, :string

      timestamps()
    end
  end
end
