defmodule Jacalendar.Itineraries.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :time_type, :string
    field :time_value, :time
    field :description, :string, default: ""
    field :sub_items, {:array, :string}, default: []
    field :end_time, :time
    field :position, :integer

    belongs_to :day, Jacalendar.Itineraries.Day

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:time_type, :time_value, :end_time, :description, :sub_items, :position, :day_id])
    |> validate_required([:time_type, :position])
  end
end
