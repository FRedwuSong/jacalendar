## ADDED Requirements

### Requirement: Checklist item persistence

The system SHALL persist checklist items to a `checklist_items` table with fields: name, location, note, checked (boolean), position, and itinerary_id.

#### Scenario: Save checklist items during itinerary creation

- **WHEN** the user submits markdown that contains a checklist section
- **THEN** the system SHALL store all parsed checklist items in the `checklist_items` table with `checked` defaulting to `false`

#### Scenario: Toggle checked state

- **WHEN** the user toggles a checklist item's checked state
- **THEN** the system SHALL update the `checked` field in the database

#### Scenario: Cascade delete

- **WHEN** an itinerary is deleted
- **THEN** the system SHALL delete all associated checklist items
