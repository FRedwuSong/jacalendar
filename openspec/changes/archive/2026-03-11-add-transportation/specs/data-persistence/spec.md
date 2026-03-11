## ADDED Requirements

### Requirement: Transport section persistence

The system SHALL persist transport sections to a `transport_sections` table with fields: section_type, title, content, position, and itinerary_id.

#### Scenario: Save transport sections during import

- **WHEN** the user imports transportation markdown that contains general sections
- **THEN** the system SHALL store all parsed sections in the `transport_sections` table

#### Scenario: Cascade delete transport sections

- **WHEN** an itinerary is deleted
- **THEN** the system SHALL delete all associated transport sections

### Requirement: Transport route persistence

The system SHALL persist transport routes to a `transport_routes` table with fields: day_label, day_date, title, segments (JSON), position, and itinerary_id.

#### Scenario: Save transport routes during import

- **WHEN** the user imports transportation markdown that contains daily route details
- **THEN** the system SHALL store all parsed routes with their segments in the `transport_routes` table

#### Scenario: Cascade delete transport routes

- **WHEN** an itinerary is deleted
- **THEN** the system SHALL delete all associated transport routes

### Requirement: Taxi address card persistence

The system SHALL persist taxi address cards to a `taxi_address_cards` table with fields: name, name_ja, address, note, position, and itinerary_id.

#### Scenario: Save address cards during import

- **WHEN** the user imports transportation markdown that contains an address card section
- **THEN** the system SHALL store all parsed address cards in the `taxi_address_cards` table

#### Scenario: Cascade delete address cards

- **WHEN** an itinerary is deleted
- **THEN** the system SHALL delete all associated taxi address cards
