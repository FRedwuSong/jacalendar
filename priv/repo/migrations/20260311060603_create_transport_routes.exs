defmodule Jacalendar.Repo.Migrations.CreateTransportRoutes do
  use Ecto.Migration

  def change do
    create table(:transport_routes) do
      add :day_label, :string, null: false
      add :day_date, :date
      add :title, :string, null: false
      add :segments, {:array, :map}, default: [], null: false
      add :position, :integer, null: false
      add :itinerary_id, references(:itineraries, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:transport_routes, [:itinerary_id])
  end
end
