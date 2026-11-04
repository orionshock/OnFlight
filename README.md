# OnFlight for WoW Forever

OnFlight shows a timer for flight-master travel and configured gossip flights. Development now targets WoW Forever, currently client 1.60.1 (interface 16001).

![Flight timer bar](.github/flight%20bar%20full.png)

The addon learns flight times as you travel and adds known or estimated durations to the taxi-map tooltip. Unknown flights count upward until arrival. A companion window groups destinations by zone and lets you mark favorites. You can customize the timer's fonts, textures, and border through LibSharedMedia.

The bundled flight times come from earlier Classic versions, mostly Horde routes. Forever routes and travel speeds may differ; completed flights update those times. Route names and the bundled gossip-flight labels are in English.

## Install

Extract a release so that `OnFlight.toc` is at:

```text
World of Warcraft/_forever_/Interface/AddOns/OnFlight/OnFlight.toc
```

Release archives include the required libraries. A source checkout needs the libraries listed in `pkgmeta.yaml` under `libs/`.

## Controls

- `/onflight` opens settings outside combat.
- Control-click and drag the timer to move it.
- Shift-click the timer to insert the remaining time into chat.
- Shift-click a destination in the companion window to toggle its favorite status.
- The taxi-map button toggles the destination window with left-click and settings with right-click.

You can disable either display module in settings. Flight tracking continues while the timer display is disabled. Enable “Show Gossip Config” to edit the gossip options that start tracked flights.

## Reloads and loading screens

`/reload`, logout, and restarting the client clear the active flight timer. They retain learned route times and your settings. The addon starts tracking again when you begin another flight.

Loading screens during a flight preserve its timer within the current UI session. The timer includes time spent loading and resumes its display on entering the world. Flights ended through early landing, a summon, or a battleground/dungeon transfer do not replace the saved route duration.

## Development and releases

The Forever API reference used for this update is the extracted `BlizzardInterfaceCode/Interface` from build 1.60.1.70755. In-game testing is still needed after client updates, particularly for travel through loading screens and gossip flights.

Tags trigger `.github/workflows/main.yml`. The workflow targets Forever 1.60.1, explicitly reads `pkgmeta.yaml`, bundles its library externals, and labels release archives `forever`. Update the TOC interface and workflow game version together for future client versions. Packaging follows the [BigWigs packager documentation](https://github.com/BigWigsMods/packager#readme).

Report bugs through [GitHub issues](https://github.com/orionshock/OnFlight/issues), including your client build, route, and any Lua error.
