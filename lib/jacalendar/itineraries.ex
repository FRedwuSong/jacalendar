defmodule Jacalendar.Itineraries do
  import Ecto.Query
  alias Jacalendar.Repo
  alias Jacalendar.Itineraries.{Itinerary, Day, Item, ChecklistItem}

  def create_itinerary(%Jacalendar.Itinerary{} = parsed) do
    {date_start, date_end} = parsed.date_range || {nil, nil}

    metadata = serialize_metadata(parsed.metadata)

    Repo.transaction(fn ->
      {:ok, itinerary} =
        %Itinerary{}
        |> Itinerary.changeset(%{
          title: parsed.title,
          date_range_start: date_start,
          date_range_end: date_end,
          metadata: metadata
        })
        |> Repo.insert()

      for {day, day_pos} <- Enum.with_index(parsed.days) do
        {:ok, db_day} =
          %Day{}
          |> Day.changeset(%{
            date: day.date,
            weekday: day.weekday,
            title: day.title,
            position: day_pos,
            itinerary_id: itinerary.id
          })
          |> Repo.insert()

        for {item, item_pos} <- Enum.with_index(day.items) do
          {time_type, time_value} = serialize_time(item.time)

          %Item{}
          |> Item.changeset(%{
            time_type: time_type,
            time_value: time_value,
            description: item.description,
            sub_items: item.sub_items,
            position: item_pos,
            day_id: db_day.id
          })
          |> Repo.insert!()
        end
      end

      for {cl, pos} <- Enum.with_index(parsed.checklist || []) do
        %ChecklistItem{}
        |> ChecklistItem.changeset(%{
          name: cl.name,
          location: cl.location,
          note: cl.note,
          position: pos,
          itinerary_id: itinerary.id
        })
        |> Repo.insert!()
      end

      itinerary.id
    end)
  end

  def list_itineraries do
    Itinerary
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_itinerary!(id) do
    Itinerary
    |> Repo.get!(id)
    |> Repo.preload([:checklist_items, days: :items])
  end

  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  def update_sub_items(%Item{} = item, sub_items) do
    item
    |> Item.changeset(%{sub_items: sub_items})
    |> Repo.update()
  end

  def delete_itinerary(%Itinerary{} = itinerary) do
    Repo.delete(itinerary)
  end

  def get_item!(id), do: Repo.get!(Item, id)

  def get_checklist_item!(id), do: Repo.get!(ChecklistItem, id)

  def toggle_checklist_item(%ChecklistItem{} = item) do
    item
    |> ChecklistItem.changeset(%{checked: !item.checked})
    |> Repo.update()
  end

  # Time serialization

  defp serialize_time({:exact, %Time{} = t}), do: {"exact", t}

  defp serialize_time({:fuzzy, period}) when period in [:morning, :afternoon, :evening],
    do: {"fuzzy_#{period}", nil}

  defp serialize_time(:pending), do: {"pending", nil}

  def deserialize_time("exact", %Time{} = t), do: {:exact, t}
  def deserialize_time("fuzzy_morning", _), do: {:fuzzy, :morning}
  def deserialize_time("fuzzy_afternoon", _), do: {:fuzzy, :afternoon}
  def deserialize_time("fuzzy_evening", _), do: {:fuzzy, :evening}
  def deserialize_time("pending", _), do: :pending

  defp serialize_airport(nil), do: nil
  defp serialize_airport(a), do: %{"code" => a.code, "name" => a.name, "time" => a.time}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp serialize_metadata(nil), do: %{}

  defp serialize_metadata(metadata) do
    %{
      "flights" =>
        Enum.map(metadata.flights || [], fn f ->
          base = %{
            "direction" => to_string(f.direction),
            "flight_number" => f.flight_number,
            "date" => f.date
          }

          base
          |> maybe_put("departure", serialize_airport(Map.get(f, :departure)))
          |> maybe_put("arrival", serialize_airport(Map.get(f, :arrival)))
          |> maybe_put("terminal", Map.get(f, :terminal))
        end),
      "hotel" =>
        if metadata.hotel do
          %{"name" => metadata.hotel.name, "address" => metadata.hotel.address}
          |> maybe_put("phone", Map.get(metadata.hotel, :phone))
        end
    }
  end
end
