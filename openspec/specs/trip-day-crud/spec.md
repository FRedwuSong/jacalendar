# trip-day-crud Specification

## Purpose

TBD - created by archiving change 'trip-day-crud'. Update Purpose after archive.

## Requirements

### Requirement: Create day via context function

The system SHALL provide a `create_day/2` function in `Itineraries` context that creates a new Day for an itinerary. The new Day SHALL have its date set to `date_range_end + 1`, its position set to the current maximum position + 1, and its weekday derived from the calculated date. The function SHALL also update the itinerary's `date_range_end` to the new date.

#### Scenario: Adding a day to a 6-day itinerary

- **WHEN** `create_day/2` is called for an itinerary with `date_range_end: ~D[2026-04-21]` and 6 days (positions 0-5)
- **THEN** a new Day SHALL be created with `date: ~D[2026-04-22]`, `position: 6`, and `weekday` derived from that date
- **AND** the itinerary's `date_range_end` SHALL be updated to `~D[2026-04-22]`

#### Scenario: Adding a day to an itinerary with no existing days

- **WHEN** `create_day/2` is called for an itinerary with no days and `date_range_start: ~D[2026-04-16]`
- **THEN** a new Day SHALL be created with `date: ~D[2026-04-16]`, `position: 0`, and `weekday` derived from that date


<!-- @trace
source: trip-day-crud
updated: 2026-03-29
code:
  - lib/jacalendar_web/live/trip_live.ex
  - lib/jacalendar/itineraries.ex
-->

---
### Requirement: Add day button in trip view

The trip view SHALL display a "+" button in the header navigation area (after the last day pill) that allows users to add a new day to the itinerary.

#### Scenario: Clicking the add day button

- **WHEN** the user clicks the "+" button in the trip view header
- **THEN** the system SHALL create a new Day via `create_day/2`
- **AND** the new day pill SHALL appear in the navigation bar
- **AND** the view SHALL navigate to the newly created day

#### Scenario: New day appears empty

- **WHEN** a new Day is created via the "+" button
- **THEN** the new Day SHALL have zero items
- **AND** the calendar column SHALL display an empty time grid


<!-- @trace
source: trip-day-crud
updated: 2026-03-29
code:
  - lib/jacalendar_web/live/trip_live.ex
  - lib/jacalendar/itineraries.ex
-->

---
### Requirement: Weekday derivation

The system SHALL derive the weekday label from the date using the same format as existing days (single Chinese character: 一, 二, 三, 四, 五, 六, 日).

#### Scenario: Weekday for a Wednesday

- **WHEN** a Day is created with `date: ~D[2026-04-22]` (Wednesday)
- **THEN** the `weekday` field SHALL be set to "三"

<!-- @trace
source: trip-day-crud
updated: 2026-03-29
code:
  - lib/jacalendar_web/live/trip_live.ex
  - lib/jacalendar/itineraries.ex
-->