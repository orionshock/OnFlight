# World transitions do not restart flights

A taxi flight is one continuous journey from confirmed boarding to actual exit. The original boarding timestamp determines elapsed time and ETA across loading screens. Displays keep their existing presentations through a world transition without suspension or resume notifications.

OnFlight retains the historical precaution of skipping taxi-state polling while the player is out of world. A potentially unreliable taxi result during that interval could be mistaken for a landing. Polling continues when the player returns to the world. Forever currently offers no taxi route that lets us verify this edge case directly.

Keeping the guard limited to polling leaves a single start and a single exit for each journey and avoids reconstructing flight or display state.
