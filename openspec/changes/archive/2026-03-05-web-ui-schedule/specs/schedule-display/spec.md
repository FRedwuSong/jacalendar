## ADDED Requirements

### Requirement: Markdown input

The system SHALL provide a textarea for users to paste markdown itinerary content and a submit button to trigger parsing.

#### Scenario: Paste and parse markdown

- **WHEN** the user pastes markdown text into the textarea and clicks the parse button
- **THEN** the system SHALL parse the markdown using `Jacalendar.MarkdownParser.parse/1` and transition to schedule view

#### Scenario: Invalid markdown

- **WHEN** the user submits markdown that cannot be parsed
- **THEN** the system SHALL display an error message and remain in input mode

### Requirement: Schedule display by day

The system SHALL display parsed itinerary items grouped by day, showing date, weekday, and day title as headers.

#### Scenario: Multi-day itinerary

- **WHEN** a 6-day itinerary is parsed
- **THEN** the system SHALL display 6 day sections, each with its date, weekday, and title

#### Scenario: Item display

- **WHEN** an item has time `{:exact, ~T[17:15:00]}`
- **THEN** it SHALL display as "17:15" followed by the description

#### Scenario: Fuzzy time display

- **WHEN** an item has time `{:fuzzy, :morning}`
- **THEN** it SHALL display a fuzzy time label (e.g., "早上") instead of a specific time

#### Scenario: Pending time display

- **WHEN** an item has time `:pending`
- **THEN** it SHALL display a visual indicator that time is not set

#### Scenario: Sub-items display

- **WHEN** an item has sub_items
- **THEN** the system SHALL display them nested under the parent item

### Requirement: Current time divider

The system SHALL display a visual divider at the current time position within the active day's schedule.

#### Scenario: Divider placement

- **WHEN** the current client time is 14:30 and viewing the current day
- **THEN** the system SHALL display a divider line between items before and after 14:30

#### Scenario: Non-current day

- **WHEN** viewing a day that is not today
- **THEN** the system SHALL NOT display the time divider for that day

### Requirement: Time editing

The system SHALL allow users to set or change time for items with fuzzy or pending time status.

#### Scenario: Edit pending time

- **WHEN** the user clicks on a pending time item's time area
- **THEN** the system SHALL display a time input field for the user to set an exact time

#### Scenario: Confirm time edit

- **WHEN** the user selects a time and confirms
- **THEN** the system SHALL update the item's time to `{:exact, selected_time}` and re-render the item in its new time position

### Requirement: Metadata display

The system SHALL display flight and hotel metadata from the parsed itinerary.

#### Scenario: Flight and hotel info

- **WHEN** the itinerary has flight and hotel metadata
- **THEN** the system SHALL display flight numbers, dates, and hotel name/address in a summary section
