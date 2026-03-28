## ADDED Requirements

### Requirement: Item end_time field

The Item schema SHALL have an optional `end_time` field of type `:time`. The field SHALL default to `nil`. The Item changeset SHALL accept `end_time` as a castable field.

#### Scenario: Item with end_time set

- **WHEN** an Item has `time_value: ~T[10:00:00]` and `end_time: ~T[12:00:00]`
- **THEN** the Item SHALL store both values in the database

#### Scenario: Item without end_time (backward compatible)

- **WHEN** an Item has `time_value: ~T[10:00:00]` and `end_time: nil`
- **THEN** the Item SHALL be valid and the display logic SHALL fall back to the next item's start time or default 1 hour

### Requirement: Event block height with end_time

The trip view SHALL calculate event block height using the following priority: (1) if the item has `end_time`, use `end_time`; (2) otherwise use the next item's `time_value`; (3) if no next item, default to 1 hour after `time_value`.

#### Scenario: Item with explicit end_time

- **WHEN** an Item has `time_value: ~T[10:00:00]` and `end_time: ~T[13:00:00]`
- **THEN** the event block height SHALL span 3 hours (10:00 to 13:00)

#### Scenario: Item without end_time followed by another item

- **WHEN** an Item has `time_value: ~T[10:00:00]`, `end_time: nil`, and the next item starts at `~T[12:00:00]`
- **THEN** the event block height SHALL span 2 hours (10:00 to 12:00)

#### Scenario: Last item without end_time

- **WHEN** an Item is the last in its day with `time_value: ~T[20:00:00]` and `end_time: nil`
- **THEN** the event block height SHALL default to 1 hour (20:00 to 21:00)

### Requirement: Edit end_time in trip view

The trip view edit mode SHALL display a time input for `end_time` alongside the existing `time_value` input. The user SHALL be able to set or clear the end time.

#### Scenario: Editing end_time

- **WHEN** the user enters `13:00` in the end_time input and saves
- **THEN** the Item's `end_time` SHALL be updated to `~T[13:00:00]`

#### Scenario: Clearing end_time

- **WHEN** the user clears the end_time input and saves
- **THEN** the Item's `end_time` SHALL be set to `nil`

### Requirement: Default end_time on item creation

When creating a new Item via the trip view, the system SHALL set `end_time` to `time_value + 1 hour` by default.

#### Scenario: Creating item at 14:00

- **WHEN** a new Item is created by clicking on the 14:00 time grid
- **THEN** the Item SHALL have `time_value: ~T[14:00:00]` and `end_time: ~T[15:00:00]`
