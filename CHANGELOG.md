# OnFlight for WoW Forever

## Updated existing functionality

- Rebuilt destination browsing and configuration with native Forever frames and Settings. Existing favorites, zone browsing, search, and duration estimation remain available.
- Kept the timer bar's appearance options and preview controls, with clearer labels and tooltips. Flight tracking and learning continue when the bar is disabled.
- Separated configuration ownership and Gossip travel hooks from the flight engine, reduced redundant display updates, and registered player-facing text with AceLocale.

## New functionality

- Numeric taxi-node identity for normal flights, timing records, and favorites. Localized flight-point names are display text only.
- A LibDataBroker flight timer and group-flight tooltip, plus a profile-specific LibDBIcon minimap button. Left-click resends the current announcement; right-click opens Settings.
- Best-effort group flight sharing with a documented four-field protocol. Solo self-whispers let the broker receive the same protocol independently.
- Gossip endpoint configuration supports verified taxi-node IDs and custom location names. Diagnostic IDs help identify dialogue options and flight destinations.

## Release scope

- WoW Forever only, using numeric taxi-node identities and Forever's native UI.
- Flight-duration learning and the existing route-estimation behavior are preserved.
- `Defaults.lua` remains the distribution file for curated timing data; its timing tables are currently empty.
- Custom named Gossip endpoints are tracked locally and are not shared through the numeric-ID protocol.
