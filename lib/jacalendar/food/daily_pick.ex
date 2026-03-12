defmodule Jacalendar.Food.DailyPick do
  use Ecto.Schema
  import Ecto.Changeset

  schema "food_daily_picks" do
    field :day_label, :string
    field :day_date, :date
    field :restaurant_name, :string
    field :priority, :string
    field :note, :string
    field :position, :integer

    timestamps()
  end

  def changeset(pick, attrs) do
    pick
    |> cast(attrs, [:day_label, :day_date, :restaurant_name, :priority, :note, :position])
    |> validate_required([:day_label, :restaurant_name, :priority, :position])
  end
end
