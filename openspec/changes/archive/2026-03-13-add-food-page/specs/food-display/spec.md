## ADDED Requirements

### Requirement: Food page accessible at standalone route

The system SHALL serve the food recommendations page at the `/food` route, independent of any itinerary ID.

#### Scenario: Navigate to food page

- **WHEN** a user navigates to `/food`
- **THEN** the food recommendations page is displayed

### Requirement: Horizontal day filter bar

The system SHALL display a horizontal scrollable day filter bar with a "全部" button and one button per day (showing date like 04/16).

#### Scenario: Default state shows all restaurants

- **WHEN** the food page loads
- **THEN** the "全部" filter is active and all restaurants are displayed grouped by category

#### Scenario: Select a specific day

- **WHEN** the user taps a day button (e.g., 04/17)
- **THEN** only restaurants recommended for that day are displayed

### Requirement: Category grouping in all-view

The system SHALL group restaurants by category (甜點, 烤魚定食, 鰻魚, 拉麵) when the "全部" filter is active, with category headings.

#### Scenario: All view displays category sections

- **WHEN** "全部" filter is active
- **THEN** restaurants are grouped under their category headings

### Requirement: Restaurant card display

Each restaurant card SHALL display: name, category badge, area, price range, hours, a one-line reason, and a Google Maps navigation link.

#### Scenario: Card with Google Maps link

- **WHEN** a restaurant card is displayed
- **THEN** tapping the map icon opens Google Maps directions from current location to the restaurant address

### Requirement: Navigation tab for food

The system SHALL add a "美食" tab to the shared navigation component, linking to `/food`.

#### Scenario: Food tab visible on all pages

- **WHEN** any page with the shared tab navigation is displayed
- **THEN** a "美食" tab is visible and links to `/food`

### Requirement: Import food markdown via file upload

The system SHALL allow uploading a food recommendation markdown file to import restaurant data.

#### Scenario: Upload and import

- **WHEN** user uploads a valid food markdown file on the food page
- **THEN** the file is parsed and restaurants are stored in the database

### Requirement: Empty state with import prompt

The system SHALL show an empty state with an import button when no food data exists.

#### Scenario: No data loaded

- **WHEN** the food page has no restaurants in the database
- **THEN** an empty state message and import button are displayed
