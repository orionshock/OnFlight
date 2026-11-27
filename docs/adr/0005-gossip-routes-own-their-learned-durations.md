# Gossip routes own their learned durations

A dialogue option can take the player between the same endpoints as an ordinary taxi and still take a different amount of time. Every gossip measurement therefore uses a source key scoped to the selected option, whether the configured source is a taxi node ID or a custom title. A numeric destination keeps its taxi node ID, and a custom destination keeps its option-scoped identity.

Removing a configuration deletes the learned duration for its configured pair from both faction tables. The scoped source protects ordinary taxi measurements even when the routes share endpoints. The existing SavedVariables are enough to express this ownership. `gossipTriggered` stores configured routes, and `flightTimes` holds measurements for both kinds of travel.

Gossip durations are useful alongside the configurations that identify their routes. Exports include configurations even before any duration has been learned. Imports preserve numeric node IDs and custom titles as distinct types, add missing entries, and keep local values when entries conflict. Older duration-only exports remain importable.
