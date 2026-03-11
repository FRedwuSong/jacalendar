defmodule Jacalendar.Itineraries.TaxiAddressCard do
  use Ecto.Schema
  import Ecto.Changeset

  schema "taxi_address_cards" do
    field :name, :string
    field :name_ja, :string
    field :address, :string
    field :note, :string
    field :position, :integer

    belongs_to :itinerary, Jacalendar.Itineraries.Itinerary

    timestamps()
  end

  def changeset(card, attrs) do
    card
    |> cast(attrs, [:name, :name_ja, :address, :note, :position, :itinerary_id])
    |> validate_required([:name, :address, :position, :itinerary_id])
  end
end
