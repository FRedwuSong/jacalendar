## ADDED Requirements

### Requirement: Day filter pills

The system SHALL display a row of pill buttons above the schedule content that allows users to filter the displayed days.

The pill row SHALL include:
- A "全部" (All) button that shows all days
- One pill per day in the itinerary

Each day pill SHALL display two lines:
- Top line: the date formatted as MM/DD
- Bottom line: the day title text

The pill row SHALL be horizontally scrollable when pills overflow the viewport width.

The currently selected pill SHALL be visually distinguished from unselected pills.

When no day is selected (default state), the "全部" pill SHALL be active and all days SHALL be displayed.

#### Scenario: Default view shows all days

- **WHEN** the user navigates to an itinerary detail page
- **THEN** the system SHALL display the "全部" pill as active and show all days

#### Scenario: Select a specific day

- **WHEN** the user clicks on a day pill (e.g., "04/17 淺草&晴空塔")
- **THEN** the system SHALL display only that day's items and mark the clicked pill as active

#### Scenario: Return to all days

- **WHEN** the user clicks the "全部" pill while a specific day is selected
- **THEN** the system SHALL display all days and mark the "全部" pill as active

#### Scenario: Horizontal scroll on small screens

- **WHEN** the itinerary has more days than can fit in the viewport width
- **THEN** the pill row SHALL be horizontally scrollable without wrapping
