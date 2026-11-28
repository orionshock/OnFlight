# Current configuration is authoritative

OnFlight targets Forever and supports one configuration model. It uses the current AceDB profiles and namespaces directly. Carrying older layouts forward adds state and branches, and keeping two preferences for the same choice makes it harder to tell which one controls the addon.

The profile's `flightDisplay` preference selects TimerBar, Quartz, or None. TimerBar's namespace owns its appearance settings. The selected display has a single stored preference. If Quartz is unavailable, OnFlight uses TimerBar and retains the saved Quartz selection.

Obsolete SavedVariables keys can remain in place. OnFlight ignores them, so there is no reason to rewrite users' files just to clear old data. Players may need to set older preferences again in the current Settings. Selecting, copying, and resetting current profiles remain supported.
