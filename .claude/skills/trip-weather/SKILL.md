---
name: trip-weather
description: >
  Fetch weather forecasts for travel itinerary destinations and integrate them into the jacalendar UI.
  Use this skill whenever the user asks about weather for their trip, destination weather, what to wear,
  or whether rain will affect their plans. Trigger phrases include city names + "天氣", "weather",
  "穿什麼", "會下雨嗎", "帶傘", "氣溫". Also use when the user wants to add weather display to the
  schedule page or update weather data in the itinerary.
---

# Trip Weather Skill

Add weather forecast data to a jacalendar travel itinerary — fetching from Open-Meteo, storing in
itinerary metadata, and displaying alongside sunrise/sunset times in the schedule UI.

## Overview

This skill has two modes:

1. **Query mode** — User asks about weather (e.g., "東京天氣"). Fetch weather data and respond with
   a summary including temperature, conditions, clothing advice, and impact on outdoor activities.

2. **Integration mode** — Add weather display to the jacalendar schedule UI, showing weather info
   next to the existing sunrise/sunset line in each day's header.

## Weather Data Source

Use **Open-Meteo API** (free, no API key required).

### Choosing the right endpoint

Open-Meteo's forecast API only covers ~16 days ahead. If the trip dates are beyond that range,
fall back to the **historical weather API** which provides climate averages for past years at the
same dates — this gives the user a reasonable "what to expect" even when precise forecasts aren't
available yet.

**Decision logic:**
1. Calculate days until trip start from today
2. If ≤ 16 days → use **Forecast endpoint** (accurate daily forecast)
3. If > 16 days → use **Historical endpoint** with previous year's dates (climate reference)
4. Always tell the user which data source you're using and its reliability level

**UI integration rule:** Only forecast data (≤ 16 days) should be written into itinerary metadata
and displayed in the schedule UI. Historical/climate reference data is for conversational responses
only — it's not precise enough to warrant a persistent UI element next to sunrise/sunset times.

### Forecast endpoint (trip within 16 days)

```
GET https://api.open-meteo.com/v1/forecast
  ?latitude={lat}&longitude={lon}
  &daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,weathercode,windspeed_10m_max
  &timezone=Asia/Tokyo
  &start_date={YYYY-MM-DD}&end_date={YYYY-MM-DD}
```

### Historical endpoint (trip beyond 16 days — climate reference)

Use the same date range but from the previous year (e.g., 2026-04-16 → 2025-04-16):

```
GET https://archive-api.open-meteo.com/v1/archive
  ?latitude={lat}&longitude={lon}
  &daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode,windspeed_10m_max
  &timezone=Asia/Tokyo
  &start_date={YYYY-MM-DD}&end_date={YYYY-MM-DD}
```

Note: the historical endpoint does NOT include `precipitation_probability_max`. When using
historical data, estimate rain likelihood from `precipitation_sum` (>0.5mm = likely rain) and
clearly label the response as "去年同期參考" (last year's reference for the same period).

### City coordinates lookup

Common destinations for this project:

| City     | Latitude | Longitude |
|----------|----------|-----------|
| 東京     | 35.6762  | 139.6503  |
| 大阪     | 34.6937  | 135.5023  |
| 京都     | 35.0116  | 135.7681  |
| 札幌     | 43.0618  | 141.3545  |
| 福岡     | 33.5904  | 130.4017  |
| 沖繩     | 26.3344  | 127.8056  |
| 名古屋   | 35.1815  | 136.9066  |
| 橫濱     | 35.4437  | 139.6380  |
| 神戶     | 34.6901  | 135.1956  |
| 奈良     | 34.6851  | 135.8048  |
| 鎌倉     | 35.3192  | 139.5467  |
| 箱根     | 35.2324  | 139.1070  |
| 輕井澤   | 36.3487  | 138.5970  |
| 日光     | 36.7500  | 139.5986  |
| 成田     | 35.7720  | 140.3929  |

If a city is not in this table, use the Open-Meteo geocoding API:
```
GET https://geocoding-api.open-meteo.com/v1/search?name={city_name}&count=1&language=ja
```

### WMO Weather Code mapping

Use these to generate human-readable conditions and icons:

| Code | Condition | Icon | 中文 |
|------|-----------|------|------|
| 0    | Clear sky | ☀️ | 晴天 |
| 1-3  | Partly cloudy | ⛅ | 多雲 |
| 45,48| Fog | 🌫️ | 霧 |
| 51-55| Drizzle | 🌦️ | 毛毛雨 |
| 61-65| Rain | 🌧️ | 下雨 |
| 66-67| Freezing rain | 🌧️❄️ | 凍雨 |
| 71-75| Snow | 🌨️ | 下雪 |
| 80-82| Rain showers | 🌦️ | 陣雨 |
| 85-86| Snow showers | 🌨️ | 陣雪 |
| 95-99| Thunderstorm | ⛈️ | 雷雨 |

## Query Mode — How to respond

When the user asks about weather, use WebFetch to call the Open-Meteo API for the trip date range.

### Response format

Respond in Traditional Chinese (繁體中文) with this structure:

### 🌤️ {城市} 天氣預報 ({date_range})

For each day in the itinerary:

**{MM/DD (weekday)}** — {icon} {condition}
- 🌡️ {min}°C ~ {max}°C
- 🌧️ 降雨機率 {precipitation_probability}%，降雨量 {precipitation}mm
- 💨 最大風速 {windspeed} km/h

Then add:

**👔 穿著建議**
Based on temperature range — suggest layers, rain gear, sun protection, etc.

**⚠️ 行程影響**
Flag days with high rain probability (>50%), extreme temperatures, or strong winds.
Mention which scheduled outdoor activities might be affected (cross-reference with itinerary items).

## Integration Mode — UI changes

When adding weather to the UI, the implementation touches these files:

### 1. Metadata structure

Weather data goes into `itinerary.metadata["weather"]` as a list, parallel to `sun_times`:

```elixir
%{
  "date" => "2026-04-16",
  "temp_max" => 22.1,
  "temp_min" => 13.5,
  "precipitation_sum" => 0.0,
  "precipitation_probability" => 10,
  "weathercode" => 1,
  "windspeed_max" => 15.2
}
```

### 2. Schedule LiveView display

Weather displays next to the sunrise/sunset span in the day header. The current pattern is:

```heex
<span :if={sun} class="ml-auto text-xs text-base-content/40 font-mono whitespace-nowrap">
  ☀ {sun["sunrise"]} — {sun["sunset"]}
</span>
```

Add weather after this span:

```heex
<span :if={weather} class="text-xs text-base-content/50 font-mono whitespace-nowrap">
  {weather_icon(weather["weathercode"])} {weather["temp_min"]}~{weather["temp_max"]}°C
  <span :if={weather["precipitation_probability"] > 40} class="text-warning">
    🌧️{weather["precipitation_probability"]}%
  </span>
</span>
```

### 3. Helper functions to add in schedule_live.ex

```elixir
defp weather_for_date(metadata, date) do
  weather = (metadata || %{})["weather"] || []
  Enum.find(weather, fn w ->
    w_date = case w["date"] do
      %Date{} = d -> d
      s when is_binary(s) -> Date.from_iso8601!(s)
      _ -> nil
    end
    w_date == date
  end)
end

defp weather_icon(code) when code in [0], do: "☀️"
defp weather_icon(code) when code in [1, 2, 3], do: "⛅"
defp weather_icon(code) when code in [45, 48], do: "🌫️"
defp weather_icon(code) when code in [51, 53, 55, 80, 81, 82], do: "🌦️"
defp weather_icon(code) when code in [61, 63, 65, 66, 67], do: "🌧️"
defp weather_icon(code) when code in [71, 73, 75, 85, 86], do: "🌨️"
defp weather_icon(code) when code in [95, 96, 99], do: "⛈️"
defp weather_icon(_), do: "🌡️"
```

### 4. Markdown parser extension

If the user wants weather in the markdown source, add a `## 🌤️ 天氣預報` section.
Otherwise, weather data can be fetched live and stored in metadata via a mix task or LiveView action.

## Key files

- `/lib/jacalendar_web/live/schedule_live.ex` — Main schedule UI (weather display here)
- `/lib/jacalendar/itineraries.ex` — Context module for itinerary CRUD
- `/lib/jacalendar/itineraries/itinerary.ex` — Itinerary schema (metadata field)
- `/lib/jacalendar/markdown_parser.ex` — Parser (if adding weather section to markdown)
