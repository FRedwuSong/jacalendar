defmodule Jacalendar.Repo.Migrations.CreateFoodRestaurants do
  use Ecto.Migration

  def change do
    create table(:food_restaurants) do
      add :name, :string, null: false
      add :category, :string, null: false
      add :area, :string
      add :price_range, :string
      add :address, :string, null: false
      add :hours, :string
      add :reason, :text
      add :position, :integer, null: false

      timestamps()
    end
  end
end
