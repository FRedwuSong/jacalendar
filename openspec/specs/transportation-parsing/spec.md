# transportation-parsing Specification

## Purpose

TBD - created by archiving change 'add-transportation'. Update Purpose after archive.

## Requirements

### Requirement: Parse transport sections

The parser SHALL extract general sections (tools, hotel transport, daily task, tips) from the transportation markdown.

#### Scenario: Parse essential tools section

- **WHEN** the parser encounters `## 📱 必備交通工具與 App` followed by content
- **THEN** it SHALL produce a section with type `tools` and the raw markdown content preserved

#### Scenario: Parse hotel transport section

- **WHEN** the parser encounters `## 🏨 飯店交通` followed by subsections for airport transfer and nearest stations
- **THEN** it SHALL produce a section with type `hotel_transport` and the content preserved

#### Scenario: Parse daily task section

- **WHEN** the parser encounters `## ☕ 每日任務` followed by hotel-to-cafe route details
- **THEN** it SHALL produce a section with type `daily_task` and the content preserved

#### Scenario: Parse tips section

- **WHEN** the parser encounters `## 💡 交通小撇步` followed by tip items
- **THEN** it SHALL produce a section with type `tips` and the content preserved


<!-- @trace
source: add-transportation
updated: 2026-03-11
code:
  - lib/jacalendar/itineraries/itinerary.ex
  - lib/jacalendar/itineraries/taxi_address_card.ex
  - lib/jacalendar/itineraries/transport_route.ex
  - priv/repo/migrations/20260311060603_create_transport_routes.exs
  - priv/repo/migrations/20260311060741_create_taxi_address_cards.exs
  - lib/jacalendar_web/router.ex
  - lib/jacalendar/itineraries.ex
  - assets/js/app.js
  - lib/jacalendar_web/live/transportation_live.ex
  - priv/repo/migrations/20260311054907_create_transport_sections.exs
  - lib/jacalendar_web/live/schedule_live.ex
  - lib/jacalendar_web/components/core_components.ex
  - lib/jacalendar_web/live/checklist_live.ex
  - lib/jacalendar/transport_parser.ex
  - lib/jacalendar/itineraries/transport_section.ex
-->

---
### Requirement: Parse daily transport routes

The parser SHALL extract per-day transport route details from `### Day N` subsections under `## 🗓️ 重點行程交通詳解`.

#### Scenario: Parse day route with segments

- **WHEN** the parser encounters `### Day 2 (4/17 五): 東東京咖啡 & Artizon` with numbered route segments
- **THEN** it SHALL produce a route with day_label `Day 2`, date `2026-04-17`, title `東東京咖啡 & Artizon`, and segments extracted from numbered items

#### Scenario: Parse route segment details

- **WHEN** a numbered segment contains from/to locations, transport method (地鐵/計程車/步行), and optional cost/duration
- **THEN** the parser SHALL extract each field into the segment structure with `from`, `to`, `method`, `details`, `cost`, and `duration`

#### Scenario: No daily routes section

- **WHEN** the transportation markdown does not contain a `重點行程交通詳解` section
- **THEN** the parser SHALL return an empty list for routes


<!-- @trace
source: add-transportation
updated: 2026-03-11
code:
  - lib/jacalendar/itineraries/itinerary.ex
  - lib/jacalendar/itineraries/taxi_address_card.ex
  - lib/jacalendar/itineraries/transport_route.ex
  - priv/repo/migrations/20260311060603_create_transport_routes.exs
  - priv/repo/migrations/20260311060741_create_taxi_address_cards.exs
  - lib/jacalendar_web/router.ex
  - lib/jacalendar/itineraries.ex
  - assets/js/app.js
  - lib/jacalendar_web/live/transportation_live.ex
  - priv/repo/migrations/20260311054907_create_transport_sections.exs
  - lib/jacalendar_web/live/schedule_live.ex
  - lib/jacalendar_web/components/core_components.ex
  - lib/jacalendar_web/live/checklist_live.ex
  - lib/jacalendar/transport_parser.ex
  - lib/jacalendar/itineraries/transport_section.ex
-->

---
### Requirement: Parse taxi address cards

The parser SHALL extract taxi/navigation address cards from the `## 📍 計程車/導航用地址卡` section.

#### Scenario: Parse address card with Japanese name and address

- **WHEN** the parser encounters a card section with `### 2. GLITCH TOKYO (日本橋)` containing Japanese name and address lines
- **THEN** it SHALL produce an address card with name `GLITCH TOKYO (日本橋)`, name_ja `GLITCH TOKYO (グリッチ トウキョウ)`, address `東京都中央区日本橋本町1-1-3 立石本町ビル 1F`, and note if present

#### Scenario: Parse address card with note

- **WHEN** a card section contains a `**備註**:` line
- **THEN** the parser SHALL include the note text in the address card

#### Scenario: No address cards section

- **WHEN** the transportation markdown does not contain a `計程車/導航用地址卡` section
- **THEN** the parser SHALL return an empty list for address cards


<!-- @trace
source: add-transportation
updated: 2026-03-11
code:
  - lib/jacalendar/itineraries/itinerary.ex
  - lib/jacalendar/itineraries/taxi_address_card.ex
  - lib/jacalendar/itineraries/transport_route.ex
  - priv/repo/migrations/20260311060603_create_transport_routes.exs
  - priv/repo/migrations/20260311060741_create_taxi_address_cards.exs
  - lib/jacalendar_web/router.ex
  - lib/jacalendar/itineraries.ex
  - assets/js/app.js
  - lib/jacalendar_web/live/transportation_live.ex
  - priv/repo/migrations/20260311054907_create_transport_sections.exs
  - lib/jacalendar_web/live/schedule_live.ex
  - lib/jacalendar_web/components/core_components.ex
  - lib/jacalendar_web/live/checklist_live.ex
  - lib/jacalendar/transport_parser.ex
  - lib/jacalendar/itineraries/transport_section.ex
-->

---
### Requirement: Parse complete transportation document

The parser SHALL accept a transportation markdown string and return a structured result.

#### Scenario: Full transportation markdown

- **WHEN** `Jacalendar.TransportParser.parse/1` is called with a valid transportation markdown string
- **THEN** it SHALL return `{:ok, %{sections: [...], routes: [...], address_cards: [...]}}` with all data populated

#### Scenario: Invalid or empty input

- **WHEN** `Jacalendar.TransportParser.parse/1` is called with an empty string or nil
- **THEN** it SHALL return `{:error, reason}` with a descriptive error message

<!-- @trace
source: add-transportation
updated: 2026-03-11
code:
  - lib/jacalendar/itineraries/itinerary.ex
  - lib/jacalendar/itineraries/taxi_address_card.ex
  - lib/jacalendar/itineraries/transport_route.ex
  - priv/repo/migrations/20260311060603_create_transport_routes.exs
  - priv/repo/migrations/20260311060741_create_taxi_address_cards.exs
  - lib/jacalendar_web/router.ex
  - lib/jacalendar/itineraries.ex
  - assets/js/app.js
  - lib/jacalendar_web/live/transportation_live.ex
  - priv/repo/migrations/20260311054907_create_transport_sections.exs
  - lib/jacalendar_web/live/schedule_live.ex
  - lib/jacalendar_web/components/core_components.ex
  - lib/jacalendar_web/live/checklist_live.ex
  - lib/jacalendar/transport_parser.ex
  - lib/jacalendar/itineraries/transport_section.ex
-->