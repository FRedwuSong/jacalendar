defmodule Jacalendar.Repo.Migrations.AddEndTimeToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :end_time, :time
    end
  end
end
