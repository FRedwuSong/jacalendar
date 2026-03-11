# transportation-display Specification

## Purpose

TBD - created by archiving change 'add-transportation'. Update Purpose after archive.

## Requirements

### Requirement: Transportation tab navigation

The system SHALL display a "交通" tab in the tab navigation bar alongside "行程表" and "清單".

#### Scenario: Tab visible on itinerary detail page

- **WHEN** the user views any itinerary page (schedule, checklist, or transportation)
- **THEN** the system SHALL display three tabs: 行程表, 清單, 交通

#### Scenario: Navigate to transportation page

- **WHEN** the user clicks the "交通" tab
- **THEN** the system SHALL navigate to `/itineraries/:id/transportation`

#### Scenario: Active tab indicator

- **WHEN** the user is on the transportation page
- **THEN** the "交通" tab SHALL be visually highlighted as active


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
### Requirement: Display transport sections

The system SHALL display general transport sections (tools, hotel transport, daily task, tips) as collapsible accordion items.

#### Scenario: Sections rendered as accordion

- **WHEN** the transportation page loads with transport sections
- **THEN** the system SHALL render each section as a collapsible block with title and content

#### Scenario: Section content in markdown

- **WHEN** a section's content contains markdown formatting (bold, lists, etc.)
- **THEN** the system SHALL render the content preserving the formatting


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
### Requirement: Display daily transport routes

The system SHALL display per-day transport routes as collapsible day groups with route segments inside.

#### Scenario: Day routes grouped and collapsible

- **WHEN** the transportation page loads with daily routes
- **THEN** the system SHALL render routes grouped by day, each group collapsible with the day title as header

#### Scenario: Route segments displayed

- **WHEN** the user expands a day's route group
- **THEN** the system SHALL display each segment with from/to locations, transport method, and details


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
### Requirement: Display taxi address cards

The system SHALL display taxi address cards as a grid of cards with copy functionality.

#### Scenario: Address cards in grid layout

- **WHEN** the transportation page loads with address cards
- **THEN** the system SHALL display cards in a responsive grid showing name, Japanese name, and address

#### Scenario: Copy address to clipboard

- **WHEN** the user clicks the copy button on an address card
- **THEN** the system SHALL copy the Japanese name and address to the clipboard

#### Scenario: Copy confirmation feedback

- **WHEN** the address is successfully copied
- **THEN** the system SHALL briefly show a "已複製" confirmation


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
### Requirement: Import transportation markdown

The system SHALL allow users to import transportation markdown for an existing itinerary.

#### Scenario: Import button on itinerary page

- **WHEN** the user views the transportation page with no transportation data
- **THEN** the system SHALL display an import area for pasting transportation markdown

#### Scenario: Successful import

- **WHEN** the user submits valid transportation markdown
- **THEN** the system SHALL parse and store the data, then display the transportation content


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
### Requirement: Empty state

The system SHALL show an appropriate empty state when no transportation data exists.

#### Scenario: No transportation data

- **WHEN** the user navigates to the transportation page and no data has been imported
- **THEN** the system SHALL display an empty state with instructions to import transportation markdown

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