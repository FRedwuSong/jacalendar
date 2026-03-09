defmodule Jacalendar.Itineraries.ChecklistItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "checklist_items" do
    field :name, :string
    field :location, :string
    field :note, :string
    field :checked, :boolean, default: false
    field :position, :integer

    belongs_to :itinerary, Jacalendar.Itineraries.Itinerary

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :location, :note, :checked, :position, :itinerary_id])
    |> validate_required([:name, :position, :itinerary_id])
  end
end
