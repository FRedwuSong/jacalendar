## ADDED Requirements

### Requirement: Create item via context function

The system SHALL provide a `create_item/2` function in `Itineraries` context that creates a new Item for a given day. The function SHALL accept a day_id and attributes map containing `time_value`, `description`, and optionally `sub_items`. The new item SHALL have `time_type` set to "exact" and `position` set to the current maximum position + 1 within that day.

#### Scenario: Creating a new item

- **WHEN** `create_item/2` is called with `day_id: 139` and `%{time_value: ~T[10:00:00], description: "New event"}`
- **THEN** a new Item SHALL be created with `time_type: "exact"`, `position` as max existing position + 1, and `sub_items: []`

#### Scenario: Creating item on empty day

- **WHEN** `create_item/2` is called for a day with zero items
- **THEN** the new Item SHALL have `position: 0`

### Requirement: Delete item via context function

The system SHALL provide a `delete_item/1` function in `Itineraries` context that deletes an Item by its struct.

#### Scenario: Deleting an item

- **WHEN** `delete_item/1` is called with a valid Item struct
- **THEN** the Item SHALL be removed from the database

### Requirement: Create item via time grid click

In trip view, the user SHALL be able to click on an empty area of the time grid to create a new item. The system SHALL use the clicked hour as the default time for the new item.

#### Scenario: Clicking on 14:00 area

- **WHEN** the user clicks on the empty grid area at the 14:00 row
- **THEN** the system SHALL create a new Item with `time_value: ~T[14:00:00]` and `description: ""` (empty)
- **AND** the system SHALL enter edit mode for the newly created item so the user can type a description

### Requirement: Edit item inline

In trip view, the user SHALL be able to click on an event block to enter edit mode. Edit mode SHALL display input fields for time and description within the event block area.

#### Scenario: Entering edit mode

- **WHEN** the user clicks on an event block
- **THEN** the event block SHALL display an editable time input and description textarea
- **AND** sub_items SHALL be editable as a list

#### Scenario: Saving edits

- **WHEN** the user modifies the time or description and submits (blur or Enter)
- **THEN** the system SHALL call `update_item/2` to persist the changes
- **AND** the event block SHALL return to display mode with updated content

#### Scenario: Cancelling edits

- **WHEN** the user presses Escape during edit mode
- **THEN** the system SHALL discard changes and return to display mode

### Requirement: Delete item via UI

In trip view, each event block SHALL display a delete button (visible on hover or in edit mode). Clicking the delete button SHALL remove the item.

#### Scenario: Deleting an item from the UI

- **WHEN** the user clicks the delete button on an event block
- **THEN** the system SHALL call `delete_item/1` to remove the item
- **AND** the event block SHALL disappear from the calendar
