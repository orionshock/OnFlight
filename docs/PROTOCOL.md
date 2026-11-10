# OnFlight flight-status protocol

WoW Forever addons can exchange flight status using Blizzard addon messages. No OnFlight installation or shared library is required.

## Transport

Register the prefix `OnFlight` with `C_ChatInfo.RegisterAddonMessagePrefix`. Send through `C_ChatInfo.SendAddonMessage` using one channel per announcement:

- `RAID` when in a normal raid.
- `PARTY` when in a normal party.
- `WHISPER` to the local character when solo.

Use `NameUtil.GetUnmodifiedUnitFullName("player")` for the self-whisper target. Forever names include surnames; do not treat the surname as a realm.

Receive through `CHAT_MSG_ADDON`, whose first four arguments are prefix, payload, channel and sender. Accept the channels above and keep sender identities as Blizzard supplies them. Receivers may include their own announcements. Guild and instance-chat channels are not used.

Delivery is best effort. There are no roster-triggered announcements, requests, handshakes or acknowledgments. Late joiners may discover flights through scheduled repeats; discovery is not guaranteed.

## Payload

Exactly four colon-separated fields:

```text
sourceNodeID:startServerTime:durationOrCommand:destinationNodeID
```

Source and destination are positive decimal integer Blizzard taxi-node IDs. Custom endpoint names are unsupported. The start time is `GetServerTime()` at confirmed boarding, in shared server seconds.

| Third field | Meaning |
| --- | --- |
| Positive decimal integer | Active flight with that measured duration in seconds |
| `U` | Active flight with an unknown duration |
| `E` | Flight actually ended, for any reason |

Examples:

```text
22:1800000000:85:25
22:1800000000:E:25
25:1800000100:U:22
25:1800000100:E:22
```

Reject zero, empty or extra fields, fractional numbers, signs and unrecognized commands. Commands are uppercase. There are no additional fields or message types.

## Sending

Keep the source, destination, boarding timestamp and advertised duration or `U` fixed throughout the flight.

- Known duration: announce on confirmed boarding, then repeat the identical payload at 30%, 50% and 70% progress. Each threshold fires once. If several thresholds are crossed during a loading gap, send once and consume all crossed thresholds.
- Unknown duration: announce `U` on confirmed boarding, then repeat the identical payload every 60 seconds. After a delayed update, send once and schedule the next repeat 60 seconds later. Never replace `U` with a number during that flight.
- Actual end: send `E` with the original source, boarding timestamp and destination. ETA expiration, an early-landing request or a loading screen does not end a flight.

An optional manual resend repeats the original announcement without changing its timestamp or scheduled repeats. Use the same schedule for solo self-whispers.

## Receiving

Keep one active flight per sender. Source, boarding timestamp and destination identify the flight.

- A strictly newer boarding timestamp replaces the current flight.
- Identical repeats refresh the last-heard time without restarting progress.
- Ignore older announcements and conflicting data at the same timestamp.
- `E` removes only the matching flight. Ignore unmatched `E` messages.

Expire unknown flights after 180 seconds without a matching announcement. For known flights, use `max(180, duration)` seconds without one. Expiry cleans up missing traffic; it does not prove landing. A short recently-ended timestamp marker can prevent delayed announcements from restoring a completed flight.

Calculate elapsed time as `max(0, GetServerTime() - startServerTime)`. For known flights, remaining time is `max(0, duration - elapsed)`. Keep overdue flights active until matching `E` or stale expiry.

Unknown flights have no ETA. Display elapsed time or an in-flight indicator until matching `E` or stale expiry; unknown duration never means zero seconds.
