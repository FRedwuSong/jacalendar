## ADDED Requirements

### Requirement: Parse day headers

The parser SHALL extract date, weekday, and title from day headers formatted as `### Day N: YYYY/MM/DD (weekday) - title`.

#### Scenario: Standard day header

- **WHEN** the parser encounters `### Day 1: 2026/04/16 (四) - 抵達與新宿之夜`
- **THEN** it SHALL produce a Day struct with date `2026-04-16`, weekday `四`, and title `抵達與新宿之夜`

#### Scenario: Day header without subtitle

- **WHEN** the parser encounters `### Day 2: 2026/04/17 (五)`
- **THEN** it SHALL produce a Day struct with date `2026-04-17`, weekday `五`, and title as empty string

### Requirement: Parse exact time items

The parser SHALL extract time and description from items with explicit `**HH:MM**:` format.

#### Scenario: Single time point

- **WHEN** the parser encounters `*   **17:15**: 抵達成田機場 (NRT)`
- **THEN** it SHALL produce an Item with time `{:exact, ~T[17:15:00]}` and description `抵達成田機場 (NRT)`

#### Scenario: Time range

- **WHEN** the parser encounters `*   **19:30-20:00**: 抵達飯店 Check-in`
- **THEN** it SHALL produce an Item with time `{:exact, ~T[19:30:00]}` and description `抵達飯店 Check-in`

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

### Requirement: Parse pending time items

Items without any recognizable time pattern SHALL be marked as pending.

#### Scenario: Item with category label only

- **WHEN** the parser encounters `*   **交通**: 搭乘利木津巴士`
- **THEN** it SHALL produce an Item with time `:pending` and description `交通: 搭乘利木津巴士`

### Requirement: Parse sub-items

The parser SHALL capture nested bullet items as sub-items of their parent item.

#### Scenario: Nested bullets under a time item

- **WHEN** an item `*   **17:15**: 抵達成田機場` has indented children `    *   完成入境手續`
- **THEN** the parent Item SHALL contain sub_items with the nested descriptions

### Requirement: Parse itinerary metadata

The parser SHALL extract flight and hotel information from the metadata sections.

#### Scenario: Flight information

- **WHEN** the parser encounters the `## ✈️ 航班資訊` section with flight details
- **THEN** it SHALL extract flight number, departure/arrival airports, and times into the metadata struct

#### Scenario: Hotel information

- **WHEN** the parser encounters the `## 🏨 住宿資訊` section
- **THEN** it SHALL extract hotel name and address into the metadata struct

### Requirement: Parse complete itinerary

The parser SHALL accept a markdown string and return a complete Itinerary struct.

#### Scenario: Full markdown file

- **WHEN** `Jacalendar.MarkdownParser.parse/1` is called with a valid itinerary markdown string
- **THEN** it SHALL return `{:ok, %Jacalendar.Itinerary{}}` with all days, items, and metadata populated

#### Scenario: Invalid or empty input

- **WHEN** `Jacalendar.MarkdownParser.parse/1` is called with an empty string or non-itinerary content
- **THEN** it SHALL return `{:error, reason}` with a descriptive error message
