defmodule Jacalendar.Itineraries.Itinerary do
  use Ecto.Schema
  import Ecto.Changeset

  schema "itineraries" do
    field :title, :string
    field :date_range_start, :date
    field :date_range_end, :date
    field :metadata, :map, default: %{}

    has_many :days, Jacalendar.Itineraries.Day, preload_order: [asc: :position]
    has_many :checklist_items, Jacalendar.Itineraries.ChecklistItem, preload_order: [asc: :position]
    has_many :transport_sections, Jacalendar.Itineraries.TransportSection, preload_order: [asc: :position]
    has_many :transport_routes, Jacalendar.Itineraries.TransportRoute, preload_order: [asc: :position]
    has_many :taxi_address_cards, Jacalendar.Itineraries.TaxiAddressCard, preload_order: [asc: :position]

    timestamps()
  end

  def changeset(itinerary, attrs) do
    itinerary
    |> cast(attrs, [:title, :date_range_start, :date_range_end, :metadata])
    |> validate_required([:title])
  end
end
