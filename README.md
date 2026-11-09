# OnFlight for WoW Forever

OnFlight is a simple taxi flight timer mod that lets you know how long it will take to get to where you are going.

![Flight Timer Bar Examples](https://github.com/orionshock/OnFlight/blob/main/.github/flight%20bar%20full.png?raw=true)

Support Taxies started by Gossip Options (and in game editor to add more as needed/desired)
Learns New Flight times or updates existing flight times as they are taken.
Flight times added to tooltip on flight map. (Comes with Horde Side flight times for Northrend, Outland, Azeroth for most flights)
Flight Destinations Window: When the Flight Master Window is open (Taxi Map) it will also show a new window that has all the destinations listed out by zone with easy to click btutons to get to where your going. Some zones are overy crowded and hard to click to get the right one.
LibSharedMedia Support for Bar Textures & Borders.


## Controls

- `/onflight` opens settings outside combat.
- Control-click and drag the timer to move it.
- Shift-click the timer to insert the remaining time into chat.
- Shift-click a destination in the companion window to toggle its favorite status.
- The taxi-map button toggles the destination window with left-click and settings with right-click.

You can disable either display module in settings. Flight tracking continues while the timer display is disabled. Enable “Show Gossip Config” to edit the gossip options that start tracked flights.


## Bugreports
Report bugs through [GitHub issues](https://github.com/orionshock/OnFlight/issues), including your client build, route, and any Lua error.

## Flight-status interoperability protocol

Other Forever flight addons can implement this protocol using Blizzard addon messages alone. OnFlight and its libraries are not required.

Register the addon-message prefix **`OnFlight`** with `C_ChatInfo.RegisterAddonMessagePrefix`. Send with `C_ChatInfo.SendAddonMessage` on `RAID` for a normal raid, otherwise `PARTY` for a normal party. Receive through `CHAT_MSG_ADDON`. No guild, whisper, or instance-chat transport is used.

### Payload

Every message contains exactly four colon-separated fields:

```text
sourceNodeID:startServerTime:durationOrCommand:destinationNodeID
```

Source and destination are positive decimal integer Blizzard taxi-node IDs. `startServerTime` is the positive integer returned by `GetServerTime()` when boarding is confirmed. It uses shared server seconds, not a local `GetTime()` value.

The third field is exactly one of:

| Value | Meaning |
| --- | --- |
| Positive decimal integer | Active flight with that measured duration in seconds |
| `U` | Active flight with an unknown duration |
| `E` | Flight actually ended, for any reason |

Examples with illustrative IDs and timestamps:

```text
22:1800000000:85:25
22:1800000000:E:25
25:1800000100:U:22
25:1800000100:E:22
```

Zero is invalid, including as a termination command. Reject empty fields, extra fields, fractional numbers, signs, and unrecognized commands. Commands are uppercase. There are no version fields or additional message types.

Namespaced custom Gossip endpoints cannot be represented by numeric node IDs. Those flights remain local; OnFlight does not invent IDs or transmit endpoint names.

### Sending schedule

Capture source, destination, boarding server timestamp, and advertised duration once. Keep these values fixed for the flight.

- For a known duration, announce on confirmed boarding. Repeat the **identical payload** when elapsed time first crosses 30%, 50%, and 70% of that original duration. Each threshold fires at most once. If a loading gap crosses several thresholds, send once and consume the crossed thresholds; never replay them in a burst.
- For an unknown duration, announce `U` on confirmed boarding and repeat the **identical payload** every 60 seconds while that flight continues. After a delayed update, send once and schedule the next announcement 60 seconds later. Never switch that flight from `U` to a number.
- Send `E` only when the actual flight ends. Preserve the original source, boarding timestamp, and destination. An expired ETA, early-landing request, loading screen, or disabled display does not mean the flight ended.

There are no roster-change messages, join announcements, sync requests, handshakes, acknowledgments, or immediate rebroadcasts when someone joins or leaves. Ordinary scheduled announcements may let late joiners discover a flight; discovery is not guaranteed. Thresholds still advance while solo. There is no deferred packet queue.

### Receiving and expiry

Keep **one active flight per sender**, keyed by the sender supplied by Blizzard. Source, boarding timestamp, and destination identify that flight.

- A valid announcement with a strictly newer boarding timestamp replaces the current record.
- An identical reannouncement refreshes its last-heard time without restarting progress or creating another record. Conflicting duration or endpoint data at the same timestamp is ignored. Older announcements cannot replace newer flights.
- `E` removes only a matching active flight. Ignore unknown and unmatched `E` messages.
- OnFlight retains one recently-ended timestamp per sender for 180 seconds. During that interval, ignore announcements at or before that timestamp. Stale removal uses the same small marker.
- Unknown flights expire after 180 seconds without a matching announcement. Known flights expire after `max(180, advertisedDuration)` seconds without one. This accommodates the wider gaps between scheduled known-flight messages. Expiry is cleanup for missing traffic, not evidence of landing.

Calculate known progress using `GetServerTime() - startServerTime` and the original advertised duration. Reaching the ETA does **not** clear the record. Unknown flights have no advertised duration: display elapsed time, an indeterminate bar, or an in-flight indicator until matching `E` or stale expiry. Unknown never means zero seconds.

OnFlight keeps communication state in memory. Reloading does not restore a local flight announcement. Disabling Communication sends no false `E`; other clients can expire that record normally. This protocol adds no flight restoration or reliability handshake.

### Local OnFlight consumers

The separate `Communication` AceAddon module consumes existing `OnFlight_Taxi_Start`, `OnFlight_Taxi_RESUME`, `OnFlight_Taxi_Stop`, and `OnFlight_Taxi_EarlyExit` messages. Loading resumes do not duplicate an existing announcement. It does not depend on timer-bar visibility or its countdown expiring.

Local addons and modules may observe these Ace messages:

- `OnFlight_RemoteFlightUpdated(sender, flight)` for a new or newer accepted flight. Identical reannouncements do not emit this message.
- `OnFlight_RemoteFlightRemoved(sender, flight, reason)` when removed. Reasons are `E`, `stale`, or `disabled`; only `E` reports an actual received end message.

`Communication:GetRemoteFlight(sender)` and `GetRemoteFlights()` expose current records for reading. Each record contains `sourceID`, `destinationID`, `startServerTime`, `duration` (nil for unknown), and `lastSeenAt` in server seconds. Consumers must not modify them.

`GetRemoteFlightProgress(sender)` returns elapsed seconds, remaining seconds, and advertised duration. Remaining time is clamped to zero for an overdue known flight while the record remains active. Both remaining time and duration are nil for unknown flights. There is no per-frame notification; displays can calculate progress as needed.
