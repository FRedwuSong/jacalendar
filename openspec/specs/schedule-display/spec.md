## Requirements

<!-- @trace
source: web-ui-schedule
updated: 2026-03-05
code:
  - lib/jacalendar_web/live/schedule_live.ex
  - lib/jacalendar/markdown_parser.ex
  - lib/jacalendar_web/router.ex
tests:
  - test/jacalendar_web/controllers/page_controller_test.exs
  - test/jacalendar_web/live/schedule_live_test.exs
-->

### Requirement: Markdown input

The system SHALL provide a textarea for users to paste markdown itinerary content and a submit button to trigger parsing.

#### Scenario: Paste and parse markdown

- **WHEN** the user pastes markdown text into the textarea and clicks the parse button
- **THEN** the system SHALL parse the markdown, save the itinerary to the database, and redirect to the itinerary detail page

#### Scenario: Invalid markdown

- **WHEN** the user submits markdown that cannot be parsed
- **THEN** the system SHALL display an error message and remain in input mode


<!-- @trace
source: data-persistence
updated: 2026-03-06
code:
  - lib/jacalendar/itineraries.ex
  - lib/jacalendar/itineraries/item.ex
  - priv/repo/migrations/20260305095031_create_itineraries.exs
  - priv/repo/migrations/20260305095058_create_days.exs
  - priv/repo/migrations/20260305095127_create_items.exs
  - lib/jacalendar_web/router.ex
  - lib/jacalendar/itineraries/day.ex
  - lib/jacalendar/itineraries/itinerary.ex
  - lib/jacalendar_web/live/schedule_live.ex
tests:
  - test/jacalendar_web/live/schedule_live_test.exs
  - test/jacalendar/itineraries_test.exs
-->

---
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

---
### Requirement: Current time divider

The system SHALL display a visual divider at the current time position within the active day's schedule.

#### Scenario: Divider placement

- **WHEN** the current client time is 14:30 and viewing the current day
- **THEN** the system SHALL display a divider line between items before and after 14:30

#### Scenario: Non-current day

- **WHEN** viewing a day that is not today
- **THEN** the system SHALL NOT display the time divider for that day

---
### Requirement: Time editing

The system SHALL allow users to set or change time for items with fuzzy or pending time status.

#### Scenario: Edit pending time

- **WHEN** the user clicks on a pending time item's time area
- **THEN** the system SHALL display a time input field for the user to set an exact time

#### Scenario: Confirm time edit

- **WHEN** the user selects a time and confirms
- **THEN** the system SHALL update the item's time to `{:exact, selected_time}` and re-render the item in its new time position

---
### Requirement: Metadata display

The system SHALL display flight and hotel metadata from the parsed itinerary.

#### Scenario: Flight and hotel info

- **WHEN** the itinerary has flight and hotel metadata
- **THEN** the system SHALL display flight numbers, dates, and hotel name/address in a summary section

---
### Requirement: Description editing

The system SHALL allow users to edit the description of any schedule item inline.

#### Scenario: Click to edit description

- **WHEN** the user clicks on an item's description text
- **THEN** the system SHALL replace the description with a text input pre-filled with the current value

#### Scenario: Confirm description edit

- **WHEN** the user presses Enter or the input loses focus
- **THEN** the system SHALL update the item's description with the new value and exit edit mode

#### Scenario: Cancel description edit

- **WHEN** the user presses Escape while editing a description
- **THEN** the system SHALL discard changes and exit edit mode

#### Scenario: Empty description

- **WHEN** the user clears the description and confirms
- **THEN** the system SHALL save an empty string as the description (the item is NOT deleted)


<!-- @trace
source: schedule-item-editing
updated: 2026-03-05
code:
  - lib/jacalendar_web/live/schedule_live.ex
tests:
  - test/jacalendar_web/live/schedule_live_test.exs
-->

---
### Requirement: Sub-item editing

The system SHALL allow users to edit any individual sub-item inline.

#### Scenario: Click to edit sub-item

- **WHEN** the user clicks on a sub-item's text
- **THEN** the system SHALL replace it with a text input pre-filled with the current value

#### Scenario: Confirm sub-item edit

- **WHEN** the user presses Enter or the input loses focus
- **THEN** the system SHALL update the sub-item text with the new value

#### Scenario: Cancel sub-item edit

- **WHEN** the user presses Escape while editing a sub-item
- **THEN** the system SHALL discard changes and exit edit mode


<!-- @trace
source: schedule-item-editing
updated: 2026-03-05
code:
  - lib/jacalendar_web/live/schedule_live.ex
tests:
  - test/jacalendar_web/live/schedule_live_test.exs
-->

---
### Requirement: Sub-item deletion

The system SHALL allow users to delete individual sub-items.

#### Scenario: Delete a sub-item

- **WHEN** the user clicks the delete button on a sub-item
- **THEN** the system SHALL remove that sub-item from the parent item


<!-- @trace
source: schedule-item-editing
updated: 2026-03-05
code:
  - lib/jacalendar_web/live/schedule_live.ex
tests:
  - test/jacalendar_web/live/schedule_live_test.exs
-->

---
### Requirement: Sub-item addition

The system SHALL allow users to add a new sub-item to any schedule item.

#### Scenario: Add new sub-item

- **WHEN** the user clicks the add sub-item button on a schedule item
- **THEN** the system SHALL display a text input for entering the new sub-item content

#### Scenario: Confirm new sub-item

- **WHEN** the user types content and presses Enter
- **THEN** the system SHALL append the new sub-item to the item's sub_items list

<!-- @trace
source: schedule-item-editing
updated: 2026-03-05
code:
  - lib/jacalendar_web/live/schedule_live.ex
tests:
  - test/jacalendar_web/live/schedule_live_test.exs
-->

---
### Requirement: Itinerary list view

The system SHALL display a list of saved itineraries on the root page alongside the input form.

#### Scenario: Show saved itineraries

- **WHEN** the user visits the root page and saved itineraries exist
- **THEN** the system SHALL display each itinerary's title and date range as clickable links

#### Scenario: No saved itineraries

- **WHEN** the user visits the root page and no itineraries exist
- **THEN** the system SHALL display only the input form without an itinerary list

<!-- @trace
source: data-persistence
updated: 2026-03-06
code:
  - lib/jacalendar/itineraries.ex
  - lib/jacalendar/itineraries/item.ex
  - priv/repo/migrations/20260305095031_create_itineraries.exs
  - priv/repo/migrations/20260305095058_create_days.exs
  - priv/repo/migrations/20260305095127_create_items.exs
  - lib/jacalendar_web/router.ex
  - lib/jacalendar/itineraries/day.ex
  - lib/jacalendar/itineraries/itinerary.ex
  - lib/jacalendar_web/live/schedule_live.ex
tests:
  - test/jacalendar_web/live/schedule_live_test.exs
  - test/jacalendar/itineraries_test.exs
-->