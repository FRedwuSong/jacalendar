## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Parse complete itinerary

The parser SHALL accept a markdown string and return a complete Itinerary struct.

#### Scenario: Full markdown file

- **WHEN** `Jacalendar.MarkdownParser.parse/1` is called with a valid itinerary markdown string
- **THEN** it SHALL return `{:ok, %Jacalendar.Itinerary{}}` with all days, items, metadata, and checklist items populated

#### Scenario: Invalid or empty input

- **WHEN** `Jacalendar.MarkdownParser.parse/1` is called with an empty string or non-itinerary content
- **THEN** it SHALL return `{:error, reason}` with a descriptive error message
