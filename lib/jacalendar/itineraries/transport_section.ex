defmodule Jacalendar.Itineraries.TransportSection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transport_sections" do
    field :section_type, :string
    field :title, :string
    field :content, :string
    field :position, :integer

    belongs_to :itinerary, Jacalendar.Itineraries.Itinerary

    timestamps()
  end

  def changeset(section, attrs) do
    section
    |> cast(attrs, [:section_type, :title, :content, :position, :itinerary_id])
    |> validate_required([:section_type, :title, :content, :position, :itinerary_id])
    |> validate_inclusion(:section_type, ~w(tools hotel_transport airport daily_task tips))
  end
end
