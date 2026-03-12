defmodule Jacalendar.Food.Restaurant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "food_restaurants" do
    field :name, :string
    field :category, :string
    field :area, :string
    field :price_range, :string
    field :address, :string
    field :hours, :string
    field :reason, :string
    field :position, :integer

    timestamps()
  end

  def changeset(restaurant, attrs) do
    restaurant
    |> cast(attrs, [:name, :category, :area, :price_range, :address, :hours, :reason, :position])
    |> validate_required([:name, :category, :address, :position])
  end
end
