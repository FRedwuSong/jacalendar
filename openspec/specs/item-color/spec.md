# item-color Specification

## Purpose

TBD - created by archiving change 'item-color'. Update Purpose after archive.

## Requirements

### Requirement: Item color field

The Item schema SHALL have an optional `color` field of type `:string`. Valid values SHALL be `nil` (default, treated as "primary"), "info", "success", "warning", and "error". The Item changeset SHALL accept `color` as a castable field.

#### Scenario: Item with color set

- **WHEN** an Item has `color: "success"`
- **THEN** the Item SHALL store "success" in the database

#### Scenario: Item without color (backward compatible)

- **WHEN** an Item has `color: nil`
- **THEN** the Item SHALL be valid and the display logic SHALL treat it as "primary"


<!-- @trace
source: item-color
updated: 2026-03-29
code:
  - lib/jacalendar_web/live/trip_live.ex
  - priv/repo/migrations/20260328174042_add_color_to_items.exs
  - lib/jacalendar/itineraries/item.ex
-->

---
### Requirement: Event block color rendering

The trip view SHALL render each event block using the daisyUI semantic color corresponding to the item's `color` value. The background SHALL use `bg-{color}/15` and the left border SHALL use `border-{color}`. The time label SHALL use `text-{color}`.

#### Scenario: Item with color "info"

- **WHEN** an Item has `color: "info"`
- **THEN** the event block SHALL have `bg-info/15` background, `border-info` left border, and `text-info` time label

#### Scenario: Item with color nil

- **WHEN** an Item has `color: nil`
- **THEN** the event block SHALL use primary colors: `bg-primary/15`, `border-primary`, `text-primary`


<!-- @trace
source: item-color
updated: 2026-03-29
code:
  - lib/jacalendar_web/live/trip_live.ex
  - priv/repo/migrations/20260328174042_add_color_to_items.exs
  - lib/jacalendar/itineraries/item.ex
-->

---
### Requirement: Color picker in edit mode

The trip view edit mode SHALL display a color picker consisting of 5 clickable color circles representing the available colors (primary, info, success, warning, error). The currently selected color SHALL be visually highlighted with a ring or border.

#### Scenario: Selecting a color

- **WHEN** the user clicks the "success" color circle in the edit mode
- **THEN** the color picker SHALL highlight the "success" circle as selected

#### Scenario: Saving color

- **WHEN** the user saves an item with "warning" color selected
- **THEN** the Item's `color` field SHALL be updated to "warning"
- **AND** the event block SHALL render with warning colors after save

<!-- @trace
source: item-color
updated: 2026-03-29
code:
  - lib/jacalendar_web/live/trip_live.ex
  - priv/repo/migrations/20260328174042_add_color_to_items.exs
  - lib/jacalendar/itineraries/item.ex
-->