## ADDED Requirements

### Requirement: Calendar timeline view for single day

When a single day is selected via the day filter pills, the system SHALL display a vertical timeline view instead of the list view. The timeline view SHALL consist of two sections:

1. An unscheduled items section at the top, displaying all fuzzy-time and pending-time items
2. A vertical timeline section below, displaying only exact-time items positioned at their scheduled times

#### Scenario: Single day with exact-time items

- **WHEN** the user selects a specific day that has items with exact times
- **THEN** the system SHALL display a vertical timeline with hour labels on the left and items positioned at their corresponding time slots

#### Scenario: Single day with no exact-time items

- **WHEN** the user selects a specific day that has only fuzzy or pending items and no exact-time items
- **THEN** the system SHALL display only the unscheduled items section and SHALL NOT display the timeline grid

#### Scenario: Unscheduled items section

- **WHEN** the user selects a specific day that has fuzzy-time or pending-time items
- **THEN** the system SHALL display those items in a separate section above the timeline, grouped by their time label (early/afternoon/evening/pending)

#### Scenario: Timeline range calculation

- **WHEN** the timeline is rendered with exact-time items
- **THEN** the timeline range SHALL start 1 hour before the earliest item (rounded down to the hour) and end 1 hour after the latest item (rounded up to the hour)

#### Scenario: All-days view unchanged

- **WHEN** the user selects the "all" filter pill
- **THEN** the system SHALL display the existing list view for all days without any timeline rendering
