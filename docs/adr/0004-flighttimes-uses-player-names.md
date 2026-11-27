# FlightTimes uses player names, not unit tokens

`CHAT_MSG_ADDON` already supplies the sender's identity. FlightTimes uses that string exactly as received for remote lookups and callbacks. Blizzard unit tokens represent temporary roster positions and can change during a flight.

Consumers that need unit tokens resolve them against their own roster. This lets FlightTimes track each flight under the same name from start to stop without traversing the roster or reassigning tokens. The public API retains four methods and two callback events.
