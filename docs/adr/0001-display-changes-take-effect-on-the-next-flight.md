# Display changes take effect on the next flight

OnFlight allows switching between TimerBar, Quartz, and None during an active flight. **A display responds only to flight events it receives while enabled.**

- When a flight starts while a display is enabled, the display presents it.
- Disabling a display during a flight clears its current presentation.
- Enabling a display during an existing flight leaves it idle until the next flight starts. A later event for the existing flight, such as a world-entry resume, is not required or expected to startup.


The OnFlight core continues tracking the active flight, learning its duration, sharing its status, and handling landing notifications under the existing eligibility rules. This keeps display selection independent of flight tracking and avoids a handoff between display modules.

## Implementation status

TimerBar and Quartz start a presentation on a flight-start event. Enabling mid-flight leaves the new display idle until the next flight. Existing bars persist through world transitions. TimerBar continues reading progress from the core, and Quartz continues using its Player bar. Disabling a display clears its presentation.
