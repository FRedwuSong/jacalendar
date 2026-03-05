## ADDED Requirements

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

### Requirement: Sub-item deletion

The system SHALL allow users to delete individual sub-items.

#### Scenario: Delete a sub-item

- **WHEN** the user clicks the delete button on a sub-item
- **THEN** the system SHALL remove that sub-item from the parent item

### Requirement: Sub-item addition

The system SHALL allow users to add a new sub-item to any schedule item.

#### Scenario: Add new sub-item

- **WHEN** the user clicks the add sub-item button on a schedule item
- **THEN** the system SHALL display a text input for entering the new sub-item content

#### Scenario: Confirm new sub-item

- **WHEN** the user types content and presses Enter
- **THEN** the system SHALL append the new sub-item to the item's sub_items list
