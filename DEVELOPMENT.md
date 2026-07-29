# Block Blast Battle Development Log

This file tracks production-readiness work, priorities, known issues, and technical debt.

## Completed Work

- 2026-07-29: Set up Rojo-based Roblox project structure for VS Code development.
- 2026-07-29: Added generated hub, battle queue pad, story placeholder pad, and spawn handling.
- 2026-07-29: Built draggable/resizable battle UI with piece previews, rainbow pieces, placement preview, and leaderboard display.
- 2026-07-29: Added first battle arena map with two player decks, arena spawns, bridge, glow pillars, walls, and scoreboard.
- 2026-07-29: Added placement pop, clear flash, invalid-placement shake, queue pulse, battle banners, hub close button, and side logo reopen behavior.
- 2026-07-29: Added round timer, solo queue countdown, and basic `Wins` leaderstat.
- 2026-07-29: Hardened placement remotes with type/range checks and cooldown throttling.
- 2026-07-29: Replaced one-off best-score saving with versioned profile data for best score and wins.
- 2026-07-29: Added hub accessibility controls for reduced motion and Auto/Large/Compact UI size.
- 2026-07-29: Added battle rewards for coins, XP, levels, winner bonus payouts, and progression display.
- 2026-07-29: Replaced story-mode placeholder with a starter solo training run using the Block Blast board.
- 2026-07-29: Added Leave Queue flow so queued players can cancel matchmaking from the hub UI.
- 2026-07-29: Added persistent settings for theme, reduced motion, and UI size through versioned profile saves.
- 2026-07-29: Added first-time onboarding panel with basic placement instructions and a saved completion flag.
- 2026-07-29: Added loading splash with fade-out and fallback dismissal for smoother first join.
- 2026-07-29: Added persistent piece skin customization with Rainbow, Neon, Pastel, and Ice generation styles.
- 2026-07-29: Added persistent sound setting and client-side cues for UI clicks, queueing, placement, blocked moves, clears, and results.
- 2026-07-29: Added isolated match sessions with per-session timers, leaderboards, finish state, and three physical arena slots.
- 2026-07-29: Added hub matchmaking status for open arenas, active matches, queue size, and full-arena feedback.
- 2026-07-29: Added visible match/arena diagnostics and a multiplayer stress-test plan for Studio local server validation.
- 2026-07-29: Added a Studio-only diagnostics overlay with current mode, arena, match, queue, and active session summaries.
- 2026-07-29: Added persistent board skin customization with Auto, Midnight, Sugar, Garden, and Contrast skins.

## Current Priorities

- Add cosmetic unlock requirements, previews, and a proper shop/inventory flow.
- Execute Studio multiplayer stress tests using the diagnostics overlay and fix issues found.
- Add richer original audio assets and mix testing.
- Expand story mode with missions, goals, dialogue, and rewards.

## Known Issues

- `BlockBlastBattle.rbxl` may be locked if Roblox Studio has it open; build to a day-specific place file instead.
- Rojo plugin connection still needs a live Roblox Studio playtest.
- Two-player battle flow needs Roblox Studio local server testing.
- First-time onboarding needs Studio validation across desktop and mobile screen sizes.
- Current battle board is UI-only; future versions should consider an optional 3D board representation in the arena.

## Technical Debt

- `BlockBlastClient.client.luau` is growing large and should be split into UI modules.
- Profile save data covers best score, wins, coins, XP, level, core settings, piece skin, and board skin; broader cosmetic inventory still needs persistence.
- Effects are client-side only and need particle polish plus final audio asset replacement.
- Match sessions now support multiple active arenas with hub availability UI and diagnostics; production still needs Studio stress execution and richer arena lifecycle tooling.

## Release Readiness

- Status: Prototype.
- Not ready for public release until multiplayer, saves, mobile UI, moderation/anti-exploit, onboarding, audio, and retention loops are tested.
