## ADDED Requirements

### Requirement: Itinerary persistence

The system SHALL persist parsed itinerary data to PostgreSQL, including all days and items with their sub-items.

#### Scenario: Save parsed itinerary

- **WHEN** the user submits markdown and it is successfully parsed
- **THEN** the system SHALL store the itinerary (title, date range, metadata), its days, and all items in the database

#### Scenario: Persist time editing

- **WHEN** the user edits an item's time via inline editing
- **THEN** the system SHALL update the item's time in the database

#### Scenario: Persist description editing

- **WHEN** the user edits an item's description via inline editing
- **THEN** the system SHALL update the item's description in the database

#### Scenario: Persist sub-item changes

- **WHEN** the user adds, edits, or deletes a sub-item
- **THEN** the system SHALL update the item's sub_items array in the database

### Requirement: Itinerary retrieval

The system SHALL load a complete itinerary from the database including all associated days and items.

#### Scenario: Load itinerary by ID

- **WHEN** the user navigates to an itinerary URL
- **THEN** the system SHALL load the itinerary with all days and items from the database and display it

#### Scenario: Data survives page refresh

- **WHEN** the user refreshes the browser on an itinerary page
- **THEN** the system SHALL reload the same itinerary data from the database

### Requirement: Itinerary listing

The system SHALL display a list of all saved itineraries for the user to choose from.

#### Scenario: List saved itineraries

- **WHEN** the user visits the root page
- **THEN** the system SHALL display a list of saved itineraries with their titles and date ranges

#### Scenario: Select an itinerary

- **WHEN** the user clicks on an itinerary in the list
- **THEN** the system SHALL navigate to that itinerary's detail page

### Requirement: Itinerary deletion

The system SHALL allow users to delete an entire itinerary and all associated data.

#### Scenario: Delete an itinerary

- **WHEN** the user clicks the delete button on an itinerary
- **THEN** the system SHALL remove the itinerary, its days, and all items from the database
