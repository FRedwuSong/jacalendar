### Requirement: Parse day headers

The parser SHALL extract date, weekday, and title from day headers formatted as `### Day N: YYYY/MM/DD (weekday) - title`.

#### Scenario: Standard day header

- **WHEN** the parser encounters `### Day 1: 2026/04/16 (四) - 抵達與新宿之夜`
- **THEN** it SHALL produce a Day struct with date `2026-04-16`, weekday `四`, and title `抵達與新宿之夜`

#### Scenario: Day header without subtitle

- **WHEN** the parser encounters `### Day 2: 2026/04/17 (五)`
- **THEN** it SHALL produce a Day struct with date `2026-04-17`, weekday `五`, and title as empty string


<!-- @trace
source: markdown-parser
updated: 2026-03-05
code:
  - lib/jacalendar/itinerary.ex
  - lib/jacalendar/markdown_parser.ex
tests:
  - test/jacalendar/markdown_parser_test.exs
-->

### Requirement: Parse exact time items

The parser SHALL extract time and description from items with explicit `**HH:MM**:` format.

#### Scenario: Single time point

- **WHEN** the parser encounters `*   **17:15**: 抵達成田機場 (NRT)`
- **THEN** it SHALL produce an Item with time `{:exact, ~T[17:15:00]}` and description `抵達成田機場 (NRT)`

#### Scenario: Time range

- **WHEN** the parser encounters `*   **19:30-20:00**: 抵達飯店 Check-in`
- **THEN** it SHALL produce an Item with time `{:exact, ~T[19:30:00]}` and description `抵達飯店 Check-in`


<!-- @trace
source: markdown-parser
updated: 2026-03-05
code:
  - lib/jacalendar/itinerary.ex
  - lib/jacalendar/markdown_parser.ex
tests:
  - test/jacalendar/markdown_parser_test.exs
-->

### Requirement: Parse fuzzy time items

The parser SHALL recognize Chinese fuzzy time expressions and map them to predefined atoms.

#### Scenario: Morning fuzzy time

- **WHEN** the parser encounters `*   **早上 (每日任務)**: 前往 coffee swamp`
- **THEN** it SHALL produce an Item with time `{:fuzzy, :morning}` and description `前往 coffee swamp`

#### Scenario: Afternoon fuzzy time

- **WHEN** the parser encounters `*   **下午**: 逛街`
- **THEN** it SHALL produce an Item with time `{:fuzzy, :afternoon}` and description `逛街`

#### Scenario: Evening fuzzy time

- **WHEN** the parser encounters `*   **晚餐**: 銀座周邊`
- **THEN** it SHALL produce an Item with time `{:fuzzy, :evening}` and description `銀座周邊`


<!-- @trace
source: markdown-parser
updated: 2026-03-05
code:
  - lib/jacalendar/itinerary.ex
  - lib/jacalendar/markdown_parser.ex
tests:
  - test/jacalendar/markdown_parser_test.exs
-->

### Requirement: Parse pending time items

Items without any recognizable time pattern SHALL be marked as pending.

#### Scenario: Item with category label only

- **WHEN** the parser encounters `*   **交通**: 搭乘利木津巴士`
- **THEN** it SHALL produce an Item with time `:pending` and description `交通: 搭乘利木津巴士`


<!-- @trace
source: markdown-parser
updated: 2026-03-05
code:
  - lib/jacalendar/itinerary.ex
  - lib/jacalendar/markdown_parser.ex
tests:
  - test/jacalendar/markdown_parser_test.exs
-->

### Requirement: Parse sub-items

The parser SHALL capture nested bullet items as sub-items of their parent item.

#### Scenario: Nested bullets under a time item

- **WHEN** an item `*   **17:15**: 抵達成田機場` has indented children `    *   完成入境手續`
- **THEN** the parent Item SHALL contain sub_items with the nested descriptions


<!-- @trace
source: markdown-parser
updated: 2026-03-05
code:
  - lib/jacalendar/itinerary.ex
  - lib/jacalendar/markdown_parser.ex
tests:
  - test/jacalendar/markdown_parser_test.exs
-->

### Requirement: Parse itinerary metadata

The parser SHALL extract flight and hotel information from the metadata sections.

#### Scenario: Flight information

- **WHEN** the parser encounters the `## ✈️ 航班資訊` section with flight details
- **THEN** it SHALL extract flight number, departure/arrival airports, and times into the metadata struct

#### Scenario: Hotel information

- **WHEN** the parser encounters the `## 🏨 住宿資訊` section
- **THEN** it SHALL extract hotel name and address into the metadata struct


<!-- @trace
source: markdown-parser
updated: 2026-03-05
code:
  - lib/jacalendar/itinerary.ex
  - lib/jacalendar/markdown_parser.ex
tests:
  - test/jacalendar/markdown_parser_test.exs
-->

### Requirement: Parse complete itinerary

The parser SHALL accept a markdown string and return a complete Itinerary struct.

#### Scenario: Full markdown file

- **WHEN** `Jacalendar.MarkdownParser.parse/1` is called with a valid itinerary markdown string
- **THEN** it SHALL return `{:ok, %Jacalendar.Itinerary{}}` with all days, items, and metadata populated

#### Scenario: Invalid or empty input

- **WHEN** `Jacalendar.MarkdownParser.parse/1` is called with an empty string or non-itinerary content
- **THEN** it SHALL return `{:error, reason}` with a descriptive error message

## Requirements

<!-- @trace
source: markdown-parser
updated: 2026-03-05
code:
  - lib/jacalendar/itinerary.ex
  - lib/jacalendar/markdown_parser.ex
tests:
  - test/jacalendar/markdown_parser_test.exs
-->


<!-- @trace
source: add-checklist
updated: 2026-03-09
code:
  - priv/repo/migrations/20260309023704_create_checklist_items.exs
  - lib/jacalendar_web/router.ex
  - lib/jacalendar/itineraries/checklist_item.ex
  - lib/jacalendar/itineraries/itinerary.ex
  - lib/jacalendar_web/live/checklist_live.ex
  - lib/jacalendar/itinerary.ex
  - lib/jacalendar/markdown_parser.ex
  - lib/jacalendar/itineraries.ex
  - lib/jacalendar_web/live/schedule_live.ex
-->

### Requirement: Parse day headers

The parser SHALL extract date, weekday, and title from day headers formatted as `### Day N: YYYY/MM/DD (weekday) - title`.

#### Scenario: Standard day header

- **WHEN** the parser encounters `### Day 1: 2026/04/16 (四) - 抵達與新宿之夜`
- **THEN** it SHALL produce a Day struct with date `2026-04-16`, weekday `四`, and title `抵達與新宿之夜`

#### Scenario: Day header without subtitle

- **WHEN** the parser encounters `### Day 2: 2026/04/17 (五)`
- **THEN** it SHALL produce a Day struct with date `2026-04-17`, weekday `五`, and title as empty string

---
### Requirement: Parse exact time items

The parser SHALL extract time and description from items with explicit `**HH:MM**:` format.

#### Scenario: Single time point

- **WHEN** the parser encounters `*   **17:15**: 抵達成田機場 (NRT)`
- **THEN** it SHALL produce an Item with time `{:exact, ~T[17:15:00]}` and description `抵達成田機場 (NRT)`

#### Scenario: Time range

- **WHEN** the parser encounters `*   **19:30-20:00**: 抵達飯店 Check-in`
- **THEN** it SHALL produce an Item with time `{:exact, ~T[19:30:00]}` and description `抵達飯店 Check-in`

---
### Requirement: Parse fuzzy time items

The parser SHALL recognize Chinese fuzzy time expressions and map them to predefined atoms.

#### Scenario: Morning fuzzy time

- **WHEN** the parser encounters `*   **早上 (每日任務)**: 前往 coffee swamp`
- **THEN** it SHALL produce an Item with time `{:fuzzy, :morning}` and description `前往 coffee swamp`

#### Scenario: Afternoon fuzzy time

- **WHEN** the parser encounters `*   **下午**: 逛街`
- **THEN** it SHALL produce an Item with time `{:fuzzy, :afternoon}` and description `逛街`

#### Scenario: Evening fuzzy time

- **WHEN** the parser encounters `*   **晚餐**: 銀座周邊`
- **THEN** it SHALL produce an Item with time `{:fuzzy, :evening}` and description `銀座周邊`

---
### Requirement: Parse pending time items

Items without any recognizable time pattern SHALL be marked as pending.

#### Scenario: Item with category label only

- **WHEN** the parser encounters `*   **交通**: 搭乘利木津巴士`
- **THEN** it SHALL produce an Item with time `:pending` and description `交通: 搭乘利木津巴士`

---
### Requirement: Parse sub-items

The parser SHALL capture nested bullet items as sub-items of their parent item.

#### Scenario: Nested bullets under a time item

- **WHEN** an item `*   **17:15**: 抵達成田機場` has indented children `    *   完成入境手續`
- **THEN** the parent Item SHALL contain sub_items with the nested descriptions

---
### Requirement: Parse itinerary metadata

The parser SHALL extract flight and hotel information from the metadata sections.

#### Scenario: Flight information

- **WHEN** the parser encounters the `## ✈️ 航班資訊` section with flight details
- **THEN** it SHALL extract flight number, departure/arrival airports, and times into the metadata struct

#### Scenario: Hotel information

- **WHEN** the parser encounters the `## 🏨 住宿資訊` section
- **THEN** it SHALL extract hotel name and address into the metadata struct

---
### Requirement: Parse complete itinerary

The parser SHALL accept a markdown string and return a complete Itinerary struct.

#### Scenario: Full markdown file

- **WHEN** `Jacalendar.MarkdownParser.parse/1` is called with a valid itinerary markdown string
- **THEN** it SHALL return `{:ok, %Jacalendar.Itinerary{}}` with all days, items, metadata, and checklist items populated

#### Scenario: Invalid or empty input

- **WHEN** `Jacalendar.MarkdownParser.parse/1` is called with an empty string or non-itinerary content
- **THEN** it SHALL return `{:error, reason}` with a descriptive error message

---
### Requirement: Parse checklist section

The parser SHALL extract checklist items from the `## 📍 必訪景點清單` section of the markdown.

#### Scenario: Numbered list with name and location

- **WHEN** the parser encounters `1.  **GLITCH TOKYO** (日本橋)`
- **THEN** it SHALL produce a checklist item with name `GLITCH TOKYO`, location `日本橋`, and note as `nil`

#### Scenario: Numbered list with name, location, and note

- **WHEN** the parser encounters `2.  **KOFFEE MAMEYA Kakeru** (清澄白河) - **需預約**`
- **THEN** it SHALL produce a checklist item with name `KOFFEE MAMEYA Kakeru`, location `清澄白河`, and note `需預約`

#### Scenario: No checklist section

- **WHEN** the markdown does not contain a `必訪景點清單` section
- **THEN** the parser SHALL return an empty list for checklist items

<!-- @trace
source: add-checklist
updated: 2026-03-09
code:
  - priv/repo/migrations/20260309023704_create_checklist_items.exs
  - lib/jacalendar_web/router.ex
  - lib/jacalendar/itineraries/checklist_item.ex
  - lib/jacalendar/itineraries/itinerary.ex
  - lib/jacalendar_web/live/checklist_live.ex
  - lib/jacalendar/itinerary.ex
  - lib/jacalendar/markdown_parser.ex
  - lib/jacalendar/itineraries.ex
  - lib/jacalendar_web/live/schedule_live.ex
-->

---
### Requirement: Separate transport parser module

The system SHALL provide a dedicated `Jacalendar.TransportParser` module for parsing transportation markdown, separate from the itinerary `MarkdownParser`.

#### Scenario: Transport parser invocation

- **WHEN** `Jacalendar.TransportParser.parse/1` is called with a transportation markdown string
- **THEN** it SHALL return structured transportation data without affecting the itinerary parser

#### Scenario: Itinerary parser unchanged

- **WHEN** `Jacalendar.MarkdownParser.parse/1` is called with an itinerary markdown string
- **THEN** it SHALL continue to return itinerary data as before, unaffected by the transport parser addition

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