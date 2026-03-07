defmodule Jacalendar.ItinerariesTest do
  use Jacalendar.DataCase, async: true

  alias Jacalendar.Itineraries

  @parsed_itinerary %Jacalendar.Itinerary{
    title: "東京之旅",
    date_range: {~D[2026-04-16], ~D[2026-04-21]},
    metadata: %{
      flights: [%{direction: :outbound, flight_number: "JL8664", date: "2026/04/16"}],
      hotel: %{name: "新宿華盛頓飯店", address: "東京都新宿区西新宿3-2-9"}
    },
    days: [
      %Jacalendar.Itinerary.Day{
        date: ~D[2026-04-16],
        weekday: "四",
        title: "抵達",
        items: [
          %Jacalendar.Itinerary.Item{
            time: {:exact, ~T[17:15:00]},
            description: "抵達成田機場",
            sub_items: ["利木津巴士直達新宿"]
          },
          %Jacalendar.Itinerary.Item{
            time: {:fuzzy, :evening},
            description: "吃拉麵",
            sub_items: []
          },
          %Jacalendar.Itinerary.Item{
            time: :pending,
            description: "搭巴士",
            sub_items: []
          }
        ]
      }
    ]
  }

  defp create_itinerary(_) do
    {:ok, id} = Itineraries.create_itinerary(@parsed_itinerary)
    itinerary = Itineraries.get_itinerary!(id)
    %{itinerary: itinerary}
  end

  describe "create_itinerary/1" do
    test "creates itinerary with days and items" do
      {:ok, id} = Itineraries.create_itinerary(@parsed_itinerary)
      itinerary = Itineraries.get_itinerary!(id)

      assert itinerary.title == "東京之旅"
      assert itinerary.date_range_start == ~D[2026-04-16]
      assert itinerary.date_range_end == ~D[2026-04-21]
      assert length(itinerary.days) == 1

      day = hd(itinerary.days)
      assert day.date == ~D[2026-04-16]
      assert day.weekday == "四"
      assert length(day.items) == 3

      item = hd(day.items)
      assert item.time_type == "exact"
      assert item.time_value == ~T[17:15:00]
      assert item.description == "抵達成田機場"
      assert item.sub_items == ["利木津巴士直達新宿"]
    end

    test "serializes fuzzy and pending times" do
      {:ok, id} = Itineraries.create_itinerary(@parsed_itinerary)
      itinerary = Itineraries.get_itinerary!(id)

      items = hd(itinerary.days).items
      fuzzy_item = Enum.find(items, &(&1.time_type == "fuzzy_evening"))
      pending_item = Enum.find(items, &(&1.time_type == "pending"))

      assert fuzzy_item.description == "吃拉麵"
      assert pending_item.description == "搭巴士"
    end
  end

  describe "list_itineraries/0" do
    setup :create_itinerary

    test "lists all itineraries", %{itinerary: itinerary} do
      list = Itineraries.list_itineraries()
      assert length(list) == 1
      assert hd(list).id == itinerary.id
    end
  end

  describe "update_item/2" do
    setup :create_itinerary

    test "updates item description", %{itinerary: itinerary} do
      item = hd(hd(itinerary.days).items)
      {:ok, updated} = Itineraries.update_item(item, %{description: "抵達羽田機場"})
      assert updated.description == "抵達羽田機場"
    end

    test "updates item time", %{itinerary: itinerary} do
      item = hd(hd(itinerary.days).items)

      {:ok, updated} =
        Itineraries.update_item(item, %{time_type: "exact", time_value: ~T[18:00:00]})

      assert updated.time_value == ~T[18:00:00]
    end
  end

  describe "update_sub_items/2" do
    setup :create_itinerary

    test "updates sub_items array", %{itinerary: itinerary} do
      item = hd(hd(itinerary.days).items)
      {:ok, updated} = Itineraries.update_sub_items(item, ["搭 N'EX", "買票"])
      assert updated.sub_items == ["搭 N'EX", "買票"]
    end
  end

  describe "delete_itinerary/1" do
    setup :create_itinerary

    test "deletes itinerary and cascades", %{itinerary: itinerary} do
      {:ok, _} = Itineraries.delete_itinerary(itinerary)
      assert Itineraries.list_itineraries() == []
    end
  end

  describe "deserialize_time/2" do
    test "deserializes all time types" do
      assert Itineraries.deserialize_time("exact", ~T[17:15:00]) == {:exact, ~T[17:15:00]}
      assert Itineraries.deserialize_time("fuzzy_morning", nil) == {:fuzzy, :morning}
      assert Itineraries.deserialize_time("fuzzy_afternoon", nil) == {:fuzzy, :afternoon}
      assert Itineraries.deserialize_time("fuzzy_evening", nil) == {:fuzzy, :evening}
      assert Itineraries.deserialize_time("pending", nil) == :pending
    end
  end
end
