## ADDED Requirements

### Requirement: Parse food recommendation markdown into structured data

The system SHALL parse a food recommendation markdown file and extract restaurant entries grouped by category, plus daily pick associations.

#### Scenario: Successful parse of complete markdown

- **WHEN** a valid food recommendation markdown is provided to FoodParser.parse/1
- **THEN** the system returns {:ok, %{restaurants: [...], daily_picks: [...]}}

### Requirement: Extract restaurant details

The system SHALL extract the following fields from each restaurant entry: name, category, area, price_range, address, hours, best_days (list), reason, and position.

#### Scenario: Restaurant with all fields present

- **WHEN** a restaurant entry has name, category heading, area, price, address, hours, best_days, and reason
- **THEN** all fields are populated in the returned restaurant map

#### Scenario: Restaurant missing optional fields

- **WHEN** a restaurant entry is missing hours or reason
- **THEN** those fields are set to nil and the restaurant is still included

### Requirement: Extract daily pick associations

The system SHALL parse the "按天安插建議" section and extract which restaurants are recommended for each day, with priority (主選 vs 備選).

#### Scenario: Day with multiple picks

- **WHEN** a day section lists restaurants with 主選 and 備選 labels
- **THEN** each pick is returned with the correct day_label, restaurant name, priority, and note

### Requirement: Recognize food categories

The system SHALL recognize the following category headings: 甜點, 烤魚定食, 鰻魚, 拉麵.

#### Scenario: All categories parsed

- **WHEN** the markdown contains all four category sections
- **THEN** each restaurant is assigned the correct category string

### Requirement: Skip restaurants without address

The system SHALL skip any restaurant entry that has no address field.

#### Scenario: Restaurant with empty address

- **WHEN** a restaurant entry has no **地址** field
- **THEN** that restaurant is excluded from the result
