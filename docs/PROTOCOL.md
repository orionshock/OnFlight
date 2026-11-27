# OnFlight flight-status protocol

## Transport

Prefix: `OnFlight`. Send to `INSTANCE_CHAT` when in an instance group, otherwise
normal `RAID`, normal `PARTY`, or self-`WHISPER` when solo. Use one channel per
announcement. OnFlight receives `INSTANCE_CHAT`, `RAID`, and `PARTY` announcements
and ignores its own. The sender key is the exact sender string delivered by
`CHAT_MSG_ADDON`. No guild distribution.

Delivery and late discovery are best effort. No requests, acknowledgments, or
roster-triggered announcements. Gossip flights are not shared.

## Payload

Exactly four colon-separated fields:

```text
sourceNodeID:startServerTime:durationOrCommand:destinationNodeID
```

Node IDs are positive decimal canonical Blizzard taxi-node IDs, not map slots.
`startServerTime` is the positive integer `GetServerTime()` at confirmed boarding.

| Third field | Meaning |
| --- | --- |
| Positive decimal integer | Active flight; total measured duration in seconds |
| `U` | Active flight; unknown duration |
| `E` | Flight ended |

Reject empty or extra fields, zero, fractions, signs, and other commands.

## Sending

Keep endpoints, boarding timestamp, and duration/`U` fixed throughout the flight.

- Known duration: announce at boarding and repeat at 30%, 50%, and 70%. Consume
  each threshold once; crossing several during a loading gap sends one repeat.
- Unknown duration: announce at boarding and every 60 seconds. After a delay,
  send once and schedule the next repeat 60 seconds later.
- End: send `E` with the original endpoints and timestamp on actual completion
  or early exit. ETA expiry, early-landing requests, and loading screens are not ends.

Manual resend repeats the original announcement without changing the schedule.

## Receiving

Keep one active flight per sender, identified by endpoints and boarding timestamp.

- A newer timestamp replaces the current flight.
- Identical repeats refresh freshness without restarting the flight.
- Ignore older announcements and conflicting data at the same timestamp.
- `E` removes only a matching flight.
- Expire after `max(180, duration)` seconds without a matching announcement;
  unknown flights use 180 seconds.
- Retain ended timestamps for 180 seconds to reject delayed announcements with
  the same or older timestamp. Unmatched `E` messages do not create a marker.

Elapsed time is `max(0, GetServerTime() - startServerTime)`. ETA expiry does not
remove an active flight; wait for matching `E` or stale expiry.

## Local Lua API

`_G.FlightTimes` is the public integration interface, independent of timer display.
Look up remote flights with the exact `CHAT_MSG_ADDON` sender string. Local
flights use Forever's `NameUtil.GetUnmodifiedUnitFullName("player")`. Consumers
that need Blizzard unit tokens resolve them against their own roster.

Z-Perl's ArcaneBar integration still uses unit tokens in callback dispatch and
initial lookups. Both paths need to migrate to the name-based contract.

```lua
FlightTimes:GetFlightInfo(playerName) -- flight table or nil
FlightTimes:GetTaxiNodeName(nodeID) -- complete Blizzard name or nil
FlightTimes:RegisterCallback(event, callback, owner) -- returns owner
FlightTimes:UnregisterCallback(event, owner)
```

`FlightStarted` and `FlightStopped` deliver `(owner, playerName, flight)`.
There is one callback per owner per event. Registration does not replay existing
flights. Repeated announcements and roster changes do not restart flights.

Flight tables are read-only:

| Field | Value |
| --- | --- |
| `sourceName`, `destinationName` | Complete, unchanged Blizzard names resolved locally, or nil |
| `sourceNodeID`, `destinationNodeID` | Canonical numeric taxi-node IDs, or nil |
| `startTime` | Receiving client's `GetTime()` seconds; approximate for remote flights |
| `duration` | Fixed total seconds or `"U"` |

`GetTaxiNodeName` also works without an active flight. Custom gossip labels are
not exposed as Blizzard names.

Flights become public after confirmed boarding or remote discovery and persist
through loading screens. Remote records follow matching end messages, replacement,
and expiration. Group departure alone leaves the record available until one of
those occurs. The stop callback receives the final table after public state is
removed. Remote timing and discovery remain best effort.
