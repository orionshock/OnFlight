# OnFlight for WoW Forever

OnFlight tracks taxi flights and learns their durations as you travel.

## Features

- Native Flight Destinations window with Favorites, zone browsing, live search.
- Measured and estimated flight times in flight-map tooltips and destination rows.
- Configurable flight timer bar.
- Party and raid flight-status sharing.

## Controls

- `/onflight` opens Settings.
- Control-drag the timer bar to move it; shift-click a timed bar to insert flight information into chat.
- Shift-click a reachable destination or the current location to toggle its favorite status.
- Left-click the taxi-map button to toggle Flight Destinations; right-click to toggle Settings.
- Left-click the broker or minimap button to resend your flight announcement; right-click to open Settings.


- Use **Gossip Configuration** to configure dialogue-triggered flights. **Show Diagnostic IDs** helps identify dialogue options and taxi nodes.

See [PROTOCOL.md](docs/PROTOCOL.md) for the public flight-status protocol.

## Flight data transfer

`/onflight export` and `/onflight import` transfer learned durations and gossip
configurations. Imports add missing entries and report conflicts while preserving
local values. Existing duration-only exports still import.

Duration records use `A|source|destination|seconds` or
`H|source|destination|seconds`. A gossip duration's source key is
`<optionID>:<nodeID or title>`. Its destination is a numeric taxi node ID or an
option-scoped title. Ordinary taxi durations use numeric IDs for both endpoints.

Configuration records use `G|optionID|source|destination`. Each endpoint uses
`N:<nodeID>` for a numeric node or `T:<optionID>:<title>` for a custom title.
For example, `G|12345|N:10|T:12345:Harbor` configures node 10 to Harbor.

## Media control dependency

The native Settings media previews use LibSharedMediaControls-1.0. The BigWigs
packager copies the `LibSharedMediaControls-1.0` folder from the latest
upstream Git tag. For a source checkout, place the runtime Lua file at
`libs/LibSharedMediaControls-1.0/LibSharedMediaControls-1.0.lua`.
