defmodule Jacalendar.MarkdownParserTest do
  use ExUnit.Case, async: true

  alias Jacalendar.MarkdownParser
  alias Jacalendar.Itinerary
  alias Jacalendar.Itinerary.Day

  @sample_markdown File.read!("/Users/sung/202604_japan_trip/tokyo_trip_itinerary_final.md")

  describe "parse/1 - complete itinerary" do
    test "parses the full markdown into an Itinerary struct" do
      assert {:ok, %Itinerary{} = itinerary} = MarkdownParser.parse(@sample_markdown)
      assert itinerary.title == "東京 6 天 5 夜咖啡與美食之旅"
      assert itinerary.date_range == {~D[2026-04-16], ~D[2026-04-21]}
      assert length(itinerary.days) == 6
    end
  end

  describe "parse/1 - invalid input" do
    test "returns error for nil" do
      assert {:error, _} = MarkdownParser.parse(nil)
    end

    test "returns error for empty string" do
      assert {:error, _} = MarkdownParser.parse("")
    end

    test "returns error for non-string" do
      assert {:error, _} = MarkdownParser.parse(123)
    end
  end

  describe "parse day headers" do
    test "extracts date, weekday, and title" do
      {:ok, itinerary} = MarkdownParser.parse(@sample_markdown)
      day1 = Enum.at(itinerary.days, 0)
      assert %Day{} = day1
      assert day1.date == ~D[2026-04-16]
      assert day1.weekday == "四"
      assert day1.title == "抵達與新宿之夜"
    end

    test "parses all 6 days" do
      {:ok, itinerary} = MarkdownParser.parse(@sample_markdown)
      dates = Enum.map(itinerary.days, & &1.date)

      assert dates == [
               ~D[2026-04-16],
               ~D[2026-04-17],
               ~D[2026-04-18],
               ~D[2026-04-19],
               ~D[2026-04-20],
               ~D[2026-04-21]
             ]
    end
  end

  describe "parse exact time items" do
    test "parses HH:MM format" do
      {:ok, itinerary} = MarkdownParser.parse(@sample_markdown)
      day1 = Enum.at(itinerary.days, 0)
      first_item = Enum.at(day1.items, 0)
      assert first_item.time == {:exact, ~T[17:15:00]}
      assert first_item.description =~ "成田機場"
    end

    test "parses time range, taking start time" do
      {:ok, itinerary} = MarkdownParser.parse(@sample_markdown)
      day1 = Enum.at(itinerary.days, 0)

      checkin = Enum.find(day1.items, fn item -> item.time == {:exact, ~T[19:30:00]} end)
      assert checkin
      assert checkin.description =~ "Check-in"
    end
  end

  describe "parse fuzzy time items" do
    test "maps morning expressions" do
      {:ok, itinerary} = MarkdownParser.parse(@sample_markdown)
      day2 = Enum.at(itinerary.days, 1)
      first_item = Enum.at(day2.items, 0)
      assert first_item.time == {:fuzzy, :morning}
      assert first_item.description =~ "coffee swamp"
    end

    test "maps afternoon expressions" do
      {:ok, itinerary} = MarkdownParser.parse(@sample_markdown)
      day2 = Enum.at(itinerary.days, 1)

      afternoon = Enum.find(day2.items, fn item -> item.time == {:fuzzy, :afternoon} end)
      assert afternoon
    end

    test "maps evening expressions" do
      {:ok, itinerary} = MarkdownParser.parse(@sample_markdown)
      day2 = Enum.at(itinerary.days, 1)

      evening = Enum.find(day2.items, fn item -> item.time == {:fuzzy, :evening} end)
      assert evening
    end
  end

  describe "parse pending time items" do
    test "items without time are marked pending" do
      {:ok, itinerary} = MarkdownParser.parse(@sample_markdown)
      day1 = Enum.at(itinerary.days, 0)

      pending_items = Enum.filter(day1.items, fn item -> item.time == :pending end)
      assert length(pending_items) > 0

      transport = Enum.find(pending_items, fn item -> item.description =~ "交通" end)
      assert transport
    end
  end

  describe "parse sub-items" do
    test "nested bullets are captured as sub_items" do
      {:ok, itinerary} = MarkdownParser.parse(@sample_markdown)
      day1 = Enum.at(itinerary.days, 0)

      transport = Enum.find(day1.items, fn item -> item.description =~ "交通" end)
      assert transport
      assert length(transport.sub_items) >= 2
    end
  end

  describe "parse metadata - flights" do
    test "extracts flight information" do
      {:ok, itinerary} = MarkdownParser.parse(@sample_markdown)
      flights = itinerary.metadata.flights
      assert length(flights) == 2

      outbound = Enum.find(flights, &(&1.direction == :outbound))
      assert outbound.flight_number == "JL8664"
      assert outbound.date == ~D[2026-04-16]

      return_flight = Enum.find(flights, &(&1.direction == :return))
      assert return_flight.flight_number == "JL099"
      assert return_flight.date == ~D[2026-04-21]
    end
  end

  describe "parse metadata - hotel" do
    test "extracts hotel information" do
      {:ok, itinerary} = MarkdownParser.parse(@sample_markdown)
      hotel = itinerary.metadata.hotel
      assert hotel.name =~ "新宿華盛頓飯店"
      assert hotel.address =~ "西新宿3-2-9"
    end
  end
end
