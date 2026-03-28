defmodule Jacalendar.Itineraries do
  import Ecto.Query
  alias Jacalendar.Repo
  alias Jacalendar.Itineraries.{Itinerary, Day, Item, ChecklistItem, TransportSection, TransportRoute, TaxiAddressCard}

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
    |> Repo.preload([
      {:checklist_items, from(c in ChecklistItem, order_by: c.position)},
      :transport_sections,
      :transport_routes,
      :taxi_address_cards,
      days: :items
    ])
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

  def create_item(day_id, attrs) do
    max_position =
      from(i in Item, where: i.day_id == ^day_id, select: max(i.position))
      |> Repo.one()
      |> Kernel.||(- 1)

    default_end_time =
      case Map.get(attrs, :time_value) do
        %Time{} = t -> Time.add(t, 3600)
        _ -> nil
      end

    %Item{}
    |> Item.changeset(
      attrs
      |> Map.put(:time_type, "exact")
      |> Map.put(:position, max_position + 1)
      |> Map.put(:day_id, day_id)
      |> Map.put_new(:sub_items, [])
      |> Map.put_new(:end_time, default_end_time)
    )
    |> Repo.insert()
  end

  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  def get_item!(id), do: Repo.get!(Item, id)

  def get_checklist_item!(id), do: Repo.get!(ChecklistItem, id)

  def toggle_checklist_item(%ChecklistItem{} = item) do
    item
    |> ChecklistItem.changeset(%{checked: !item.checked})
    |> Repo.update()
  end

  def import_transportation(itinerary_id, %{sections: sections, routes: routes, address_cards: cards}) do
    Repo.transaction(fn ->
      # Delete existing transport data for this itinerary
      from(t in TransportSection, where: t.itinerary_id == ^itinerary_id) |> Repo.delete_all()
      from(t in TransportRoute, where: t.itinerary_id == ^itinerary_id) |> Repo.delete_all()
      from(t in TaxiAddressCard, where: t.itinerary_id == ^itinerary_id) |> Repo.delete_all()

      for s <- sections do
        %TransportSection{}
        |> TransportSection.changeset(Map.put(s, :itinerary_id, itinerary_id))
        |> Repo.insert!()
      end

      for r <- routes do
        %TransportRoute{}
        |> TransportRoute.changeset(Map.put(r, :itinerary_id, itinerary_id))
        |> Repo.insert!()
      end

      for c <- cards do
        %TaxiAddressCard{}
        |> TaxiAddressCard.changeset(Map.put(c, :itinerary_id, itinerary_id))
        |> Repo.insert!()
      end

      :ok
    end)
  end

  def reorder_checklist_items(ids) when is_list(ids) do
    Repo.transaction(fn ->
      ids
      |> Enum.with_index()
      |> Enum.each(fn {id, pos} ->
        from(c in ChecklistItem, where: c.id == ^id)
        |> Repo.update_all(set: [position: pos])
      end)
    end)
  end

  def create_day(%Itinerary{} = itinerary) do
    itinerary = Repo.preload(itinerary, :days)

    {new_date, new_position} =
      case itinerary.days do
        [] -> {itinerary.date_range_start, 0}
        days ->
          max_position = days |> Enum.map(& &1.position) |> Enum.max()
          {Date.add(itinerary.date_range_end, 1), max_position + 1}
      end

    weekday = weekday_from_date(new_date)

    Repo.transaction(fn ->
      {:ok, day} =
        %Day{}
        |> Day.changeset(%{
          date: new_date,
          weekday: weekday,
          position: new_position,
          itinerary_id: itinerary.id
        })
        |> Repo.insert()

      {:ok, _} =
        itinerary
        |> Itinerary.changeset(%{date_range_end: new_date})
        |> Repo.update()

      day
    end)
  end

  @weekday_labels %{1 => "一", 2 => "二", 3 => "三", 4 => "四", 5 => "五", 6 => "六", 7 => "日"}

  def weekday_from_date(%Date{} = date) do
    Map.fetch!(@weekday_labels, Date.day_of_week(date))
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

  defp serialize_airport(a) do
    %{"code" => a.code, "name" => a.name, "time" => a.time}
    |> maybe_put("terminal", Map.get(a, :terminal))
  end

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
        end,
      "sun_times" =>
        Enum.map(Map.get(metadata, :sun_times) || [], fn st ->
          %{"date" => st.date, "sunrise" => st.sunrise, "sunset" => st.sunset}
        end)
    }
  end
end
