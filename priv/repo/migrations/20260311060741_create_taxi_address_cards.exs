defmodule Jacalendar.Repo.Migrations.CreateTaxiAddressCards do
  use Ecto.Migration

  def change do
    create table(:taxi_address_cards) do
      add :name, :string, null: false
      add :name_ja, :string
      add :address, :string, null: false
      add :note, :string
      add :position, :integer, null: false
      add :itinerary_id, references(:itineraries, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:taxi_address_cards, [:itinerary_id])
  end
end
