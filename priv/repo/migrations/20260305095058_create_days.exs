defmodule Jacalendar.Repo.Migrations.CreateDays do
  use Ecto.Migration

  def change do
    create table(:days) do
      add :date, :date, null: false
      add :weekday, :string, null: false
      add :title, :string
      add :position, :integer, null: false
      add :itinerary_id, references(:itineraries, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:days, [:itinerary_id])
  end
end
