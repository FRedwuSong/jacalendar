defmodule Jacalendar.Repo.Migrations.CreateFoodDailyPicks do
  use Ecto.Migration

  def change do
    create table(:food_daily_picks) do
      add :day_label, :string, null: false
      add :day_date, :date
      add :restaurant_name, :string, null: false
      add :priority, :string, null: false
      add :note, :text
      add :position, :integer, null: false

      timestamps()
    end
  end
end
