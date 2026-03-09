defmodule Jacalendar.Repo.Migrations.CreateChecklistItems do
  use Ecto.Migration

  def change do
    create table(:checklist_items) do
      add :name, :string, null: false
      add :location, :string
      add :note, :string
      add :checked, :boolean, default: false, null: false
      add :position, :integer, null: false
      add :itinerary_id, references(:itineraries, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:checklist_items, [:itinerary_id])
  end
end
