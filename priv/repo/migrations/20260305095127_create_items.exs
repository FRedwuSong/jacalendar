defmodule Jacalendar.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :time_type, :string, null: false
      add :time_value, :time
      add :description, :string, null: false, default: ""
      add :sub_items, {:array, :string}, null: false, default: []
      add :position, :integer, null: false
      add :day_id, references(:days, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:items, [:day_id])
  end
end
