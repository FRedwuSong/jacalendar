defmodule Jacalendar.Food do
  import Ecto.Query
  alias Jacalendar.Repo
  alias Jacalendar.Food.{Restaurant, DailyPick}

  def list_restaurants do
    Restaurant
    |> order_by(:position)
    |> Repo.all()
  end

  def daily_picks_for_date(date) do
    DailyPick
    |> where([p], p.day_date == ^date)
    |> order_by(:position)
    |> Repo.all()
  end

  def list_daily_picks do
    DailyPick
    |> order_by(:position)
    |> Repo.all()
  end

  def import_food(%{restaurants: restaurants, daily_picks: daily_picks}) do
    Repo.transaction(fn ->
      Repo.delete_all(DailyPick)
      Repo.delete_all(Restaurant)

      for r <- restaurants do
        %Restaurant{}
        |> Restaurant.changeset(r)
        |> Repo.insert!()
      end

      for p <- daily_picks do
        %DailyPick{}
        |> DailyPick.changeset(p)
        |> Repo.insert!()
      end

      :ok
    end)
  end

  def has_data? do
    Repo.exists?(Restaurant)
  end
end
