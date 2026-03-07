defmodule Jacalendar.Itineraries.Day do
  use Ecto.Schema
  import Ecto.Changeset

  schema "days" do
    field :date, :date
    field :weekday, :string
    field :title, :string
    field :position, :integer

    belongs_to :itinerary, Jacalendar.Itineraries.Itinerary
    has_many :items, Jacalendar.Itineraries.Item, preload_order: [asc: :position]

    timestamps()
  end

  def changeset(day, attrs) do
    day
    |> cast(attrs, [:date, :weekday, :title, :position, :itinerary_id])
    |> validate_required([:date, :weekday, :position])
  end
end
