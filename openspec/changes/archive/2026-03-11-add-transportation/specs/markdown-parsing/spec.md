## ADDED Requirements

### Requirement: Separate transport parser module

The system SHALL provide a dedicated `Jacalendar.TransportParser` module for parsing transportation markdown, separate from the itinerary `MarkdownParser`.

#### Scenario: Transport parser invocation

- **WHEN** `Jacalendar.TransportParser.parse/1` is called with a transportation markdown string
- **THEN** it SHALL return structured transportation data without affecting the itinerary parser

#### Scenario: Itinerary parser unchanged

- **WHEN** `Jacalendar.MarkdownParser.parse/1` is called with an itinerary markdown string
- **THEN** it SHALL continue to return itinerary data as before, unaffected by the transport parser addition
