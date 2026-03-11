defmodule Jacalendar.Itineraries.TransportRoute do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transport_routes" do
    field :day_label, :string
    field :day_date, :date
    field :title, :string
    field :segments, {:array, :map}, default: []
    field :position, :integer

    belongs_to :itinerary, Jacalendar.Itineraries.Itinerary

    timestamps()
  end

  def changeset(route, attrs) do
    route
    |> cast(attrs, [:day_label, :day_date, :title, :segments, :position, :itinerary_id])
    |> validate_required([:day_label, :title, :segments, :position, :itinerary_id])
  end
end
