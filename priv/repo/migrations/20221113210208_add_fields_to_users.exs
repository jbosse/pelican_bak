defmodule Pelican.Repo.Migrations.AddFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string
      add :username, :string
      add :birthdate, :date
      add :country_id, references("countries")
      add :phone_number, :string
      add :bio, :string
      add :location, :string
      add :timezone, :string
      add :confirmation_code, :string
    end

    create unique_index(:users, [:country_id, :phone_number])
  end
end
