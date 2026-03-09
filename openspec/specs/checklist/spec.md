# checklist Specification

## Purpose

TBD - created by archiving change 'add-checklist'. Update Purpose after archive.

## Requirements

### Requirement: Display checklist

The system SHALL display a checklist page at `/itineraries/:id/checklist` showing all parsed checklist items for an itinerary.

#### Scenario: View checklist with items

- **WHEN** the user navigates to `/itineraries/:id/checklist`
- **THEN** the system SHALL display all checklist items with their name, location, and note, ordered by position

#### Scenario: View checklist with no items

- **WHEN** the user navigates to `/itineraries/:id/checklist` and the itinerary has no checklist items
- **THEN** the system SHALL display an empty state message


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
### Requirement: Toggle checklist item

The system SHALL allow users to toggle the checked state of a checklist item.

#### Scenario: Check an unchecked item

- **WHEN** the user clicks on an unchecked checklist item
- **THEN** the system SHALL set the item's `checked` field to `true` and persist it to the database

#### Scenario: Uncheck a checked item

- **WHEN** the user clicks on a checked checklist item
- **THEN** the system SHALL set the item's `checked` field to `false` and persist it to the database


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
### Requirement: Tab navigation between schedule and checklist

The system SHALL provide tab navigation to switch between the schedule view and checklist view.

#### Scenario: Navigate from schedule to checklist

- **WHEN** the user is on `/itineraries/:id` and clicks the "清單" tab
- **THEN** the system SHALL navigate to `/itineraries/:id/checklist`

#### Scenario: Navigate from checklist to schedule

- **WHEN** the user is on `/itineraries/:id/checklist` and clicks the "行程表" tab
- **THEN** the system SHALL navigate to `/itineraries/:id`

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