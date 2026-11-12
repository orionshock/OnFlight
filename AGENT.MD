AGENTS.md — World of Warcraft Addon Development

1. Understand the Environment

WoW addons operate inside Blizzard's Lua runtime, event system, APIs, and secure execution environment. Conventional software engineering assumptions do not always apply.

- Follow the target client's established conventions and actual API behavior. Do not assume compatibility across WoW versions.
- Consult Blizzard's UI source (FrameXML) and experienced addon implementations when behavior or conventions are unclear.
- Prefer Blizzard's existing facilities over recreating functionality the client already provides.
- Respect protected operations, combat lockdown, taint, and other client-specific restrictions where relevant.
- Investigate undocumented behavior in the actual client rather than guessing.

2. Respect Scope and Ownership

Complete the requested work, including what is necessary to make it correct and usable, without inventing additional requirements.

- Preserve established behavior, architecture, and project conventions unless authorized to change them.
- Make routine implementation decisions within existing boundaries. Escalate changes to established contracts, major responsibilities, or architecture.
- Treat existing implementations as behavioral references, not invitations to redesign.
- Distinguish necessary correctness handling from speculative defensive code. Not every exceptional condition requires intervention; sometimes returning without action and waiting for the next natural game event is correct.
- When a request cannot be completed within established constraints, explain the conflict rather than making unauthorized changes.

3. Keep It Simple (KISS)

Prefer straightforward, idiomatic Lua and the least complicated solution appropriate to the problem.

- Avoid unnecessary abstractions, wrappers, dependencies, configuration, and defensive machinery.
- Delete Test: If removing an abstraction simplifies the code without materially harming clarity, correctness, or maintainability, it probably shouldn't exist.
- 300-Line Smell: A file approaching roughly 300 lines warrants reviewing its responsibilities, not automatically splitting it. This is a heuristic, never a limit.
- Split by genuine responsibility boundaries, not size. More files introduce interfaces, dependencies, and navigation overhead. A cohesive larger file is often preferable.
- Don't refactor unrelated code simply because an improvement is possible.

4. Validate in the Actual Client

The WoW client is the behavioral test environment.

- Validate behavior through in-game execution and diagnostic instrumentation. Do not build offline WoW simulation harnesses, mocked Blizzard APIs, or behavioral test suites.
- Lua compilation and linting can catch static issues but provide no evidence of correct behavior in the WoW client.
- When behavior is uncertain, instrument relevant code to expose real API returns, event sequences, arguments, state transitions, and decision inputs.
- Prefer targeted diagnostics; use detailed function tracing when necessary. Remove temporary instrumentation when its purpose is fulfilled.
- When the agent cannot run the client, identify unresolved runtime assumptions and provide concise, specific guidance for human verification.
- Never claim in-game correctness based on static checks or assumptions.

5. Respect the Addon Ecosystem

An addon shares its environment with Blizzard's UI, other addons, and players who may not have installed it.

- Avoid unnecessary chat spam, addon-message traffic, protected-frame interference, and unwanted effects on other players.
- Respect established interoperability conventions and existing addon interfaces.
- Communicate only information recipients need; avoid duplicating data already available through Blizzard.
- Prefer established transport and library facilities over custom synchronization or integration frameworks.
- Favor sensible defaults and minimal configuration. Players should rarely need to configure an addon to benefit from it.

6. Communicate with Purpose

Documentation and reports should serve their intended audience, not chronicle the development process.

- Document durable contracts, important boundaries, and non-obvious rationale—not routine implementation details.
- Write protocol documentation for implementers, release notes for players, and diagnostic output for debugging.
- Keep explanations concise and proportionate to their purpose.
- Don't create stage reports, planning documents, implementation summaries, or other permanent artifacts unless requested.
- Report changes and verification results briefly. Distinguish static checks from actual client observations.

---

Guiding principle: Understand what the WoW client already owns before deciding what the addon must implement. Respect established boundaries, exercise judgment within scope, and introduce only complexity that serves a demonstrated purpose.