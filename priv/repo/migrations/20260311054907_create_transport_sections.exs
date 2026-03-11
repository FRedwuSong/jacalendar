defmodule Jacalendar.Repo.Migrations.CreateTransportSections do
  use Ecto.Migration

  def change do
    create table(:transport_sections) do
      add :section_type, :string, null: false
      add :title, :string, null: false
      add :content, :text, null: false
      add :position, :integer, null: false
      add :itinerary_id, references(:itineraries, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:transport_sections, [:itinerary_id])
  end
end
