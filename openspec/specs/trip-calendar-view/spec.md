# trip-calendar-view Specification

## Purpose

TBD - created by archiving change 'trip-calendar-view'. Update Purpose after archive.

## Requirements

### Requirement: Week view route

The system SHALL serve a week view at `/trip/:id/all` that displays all days of the itinerary in a multi-column layout resembling Google Calendar's week view.

#### Scenario: Navigating to week view

- **WHEN** user visits `/trip/:id/all` with a valid itinerary ID
- **THEN** the system SHALL display all days as side-by-side columns with a shared vertical time axis from 07:00 to 24:00

#### Scenario: Invalid itinerary ID

- **WHEN** user visits `/trip/:id/all` with a non-existent itinerary ID
- **THEN** the system SHALL return a 404 error


<!-- @trace
source: trip-calendar-view
updated: 2026-03-28
code:
  - lib/jacalendar_web/router.ex
  - assets/js/app.js
  - lib/jacalendar_web/live/trip_live.ex
-->

---
### Requirement: Single day view route

The system SHALL serve a single day view at `/trip/:id/:day` where `:day` is a 1-based day number (position + 1) within the itinerary.

#### Scenario: Navigating to a specific day

- **WHEN** user visits `/trip/:id/3` for an itinerary with 6 days
- **THEN** the system SHALL display day 3 in a single-column layout with a vertical time axis from 07:00 to 24:00

#### Scenario: Day number out of range

- **WHEN** user visits `/trip/:id/7` for an itinerary with 6 days
- **THEN** the system SHALL redirect to `/trip/:id/all`

#### Scenario: Day parameter is "all"

- **WHEN** user visits `/trip/:id/all`
- **THEN** the system SHALL render the week view, not treat "all" as a day number


<!-- @trace
source: trip-calendar-view
updated: 2026-03-28
code:
  - lib/jacalendar_web/router.ex
  - assets/js/app.js
  - lib/jacalendar_web/live/trip_live.ex
-->

---
### Requirement: Time axis layout

The system SHALL render a vertical time axis on the left side spanning from 07:00 to 24:00 (next midnight). The time axis SHALL be shared across all columns in week view and SHALL label each hour.

#### Scenario: Time axis rendering

- **WHEN** the trip view is rendered (week or single day)
- **THEN** the left side SHALL display hour labels from 07:00 to 24:00 and the content area SHALL be vertically scrollable


<!-- @trace
source: trip-calendar-view
updated: 2026-03-28
code:
  - lib/jacalendar_web/router.ex
  - assets/js/app.js
  - lib/jacalendar_web/live/trip_live.ex
-->

---
### Requirement: Event block rendering

Each itinerary item with an exact time SHALL be rendered as an event block positioned at its corresponding time on the vertical axis. The block height SHALL represent the duration until the next item or a default of 1 hour if it is the last item of the day.

#### Scenario: Item with exact time

- **WHEN** an item has `time_type: "exact"` and `time_value: 10:00`
- **THEN** the event block SHALL be positioned at the 10:00 row on the time grid

#### Scenario: Duration calculation from next item

- **WHEN** an item starts at 10:00 and the next item in the same day starts at 12:00
- **THEN** the event block height SHALL span 2 hours (from 10:00 to 12:00)

#### Scenario: Last item of the day

- **WHEN** an item is the last item in a day starting at 20:00
- **THEN** the event block height SHALL default to 1 hour (20:00 to 21:00)


<!-- @trace
source: trip-calendar-view
updated: 2026-03-28
code:
  - lib/jacalendar_web/router.ex
  - assets/js/app.js
  - lib/jacalendar_web/live/trip_live.ex
-->

---
### Requirement: Auto-scroll on page load

The page SHALL automatically scroll to a reasonable starting position on load so the user does not start at the top of the 07:00 axis.

#### Scenario: Initial scroll position

- **WHEN** the trip view finishes loading
- **THEN** the page SHALL scroll to approximately 08:00 on the time axis


<!-- @trace
source: trip-calendar-view
updated: 2026-03-28
code:
  - lib/jacalendar_web/router.ex
  - assets/js/app.js
  - lib/jacalendar_web/live/trip_live.ex
-->

---
### Requirement: Week view column layout

In week view (`/trip/:id/all`), each day SHALL be rendered as a column. The column header SHALL display the day number, date, and weekday. All columns SHALL share the same time grid.

#### Scenario: Column headers

- **WHEN** week view is rendered for a 6-day itinerary starting 2026-04-16
- **THEN** columns SHALL display headers like "Day 1 · 4/16 (四)", "Day 2 · 4/17 (五)", etc.

#### Scenario: Mobile horizontal scroll

- **WHEN** week view is rendered on a narrow viewport
- **THEN** the columns SHALL be horizontally scrollable while the time axis remains fixed on the left


<!-- @trace
source: trip-calendar-view
updated: 2026-03-28
code:
  - lib/jacalendar_web/router.ex
  - assets/js/app.js
  - lib/jacalendar_web/live/trip_live.ex
-->

---
### Requirement: Single day full-width layout

In single day view (`/trip/:id/:day`), the single column SHALL expand to full width of the viewport. Navigation between days SHALL be available.

#### Scenario: Full-width rendering

- **WHEN** single day view is rendered on mobile
- **THEN** the event column SHALL use the full available width

#### Scenario: Day navigation

- **WHEN** user is viewing `/trip/:id/3`
- **THEN** navigation controls SHALL allow moving to day 2 and day 4, as well as the "all" view

<!-- @trace
source: trip-calendar-view
updated: 2026-03-28
code:
  - lib/jacalendar_web/router.ex
  - assets/js/app.js
  - lib/jacalendar_web/live/trip_live.ex
-->