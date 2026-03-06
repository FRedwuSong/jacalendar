defmodule Jacalendar.Repo.Migrations.CreateItineraries do
  use Ecto.Migration

  def change do
    create table(:itineraries) do
      add :title, :string, null: false
      add :date_range_start, :date
      add :date_range_end, :date
      add :metadata, :map, default: %{}

      timestamps()
    end
  end
end
