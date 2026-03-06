## MODIFIED Requirements

### Requirement: Markdown input

The system SHALL provide a textarea for users to paste markdown itinerary content and a submit button to trigger parsing.

#### Scenario: Paste and parse markdown

- **WHEN** the user pastes markdown text into the textarea and clicks the parse button
- **THEN** the system SHALL parse the markdown, save the itinerary to the database, and redirect to the itinerary detail page

#### Scenario: Invalid markdown

- **WHEN** the user submits markdown that cannot be parsed
- **THEN** the system SHALL display an error message and remain in input mode

## ADDED Requirements

### Requirement: Itinerary list view

The system SHALL display a list of saved itineraries on the root page alongside the input form.

#### Scenario: Show saved itineraries

- **WHEN** the user visits the root page and saved itineraries exist
- **THEN** the system SHALL display each itinerary's title and date range as clickable links

#### Scenario: No saved itineraries

- **WHEN** the user visits the root page and no itineraries exist
- **THEN** the system SHALL display only the input form without an itinerary list
