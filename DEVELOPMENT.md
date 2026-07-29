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
- 2026-07-29: Hardened queue/settings remotes with queue action cooldowns, explicit mode handling, and debounced settings saves.
- 2026-07-29: Expanded Story Training into rotating server-authored missions with visible objectives, completion rewards, and persistent Story Stars.
- 2026-07-29: Added compact touch layout for the battle window with stacked board/piece controls and safer small-screen scaling.
- 2026-07-29: Added progression-gated cosmetic unlock requirements for piece and board skins with server-side enforcement and hub hints.
- 2026-07-29: Added hub story chapter preview showing the next mission title, objective, and Story Stars before starting Story Training.
- 2026-07-29: Hardened profile persistence with bounded save retries, DataStore load/save warnings, shutdown save sweep, and Studio save-failure diagnostics.
- 2026-07-29: Added server playtest analytics counters for battle/story sessions, queue joins/leaves, placements, clears, invalid placements, and story completions.
- 2026-07-29: Prevented early-leave reward farming by treating active run exits as forfeits with no payout and tracking forfeits in diagnostics.
- 2026-07-29: Added suspicious placement-request diagnostics for malformed, stale-session, and cooldown-throttled placement remotes.
- 2026-07-29: Added visual cosmetic swatches to hub piece and board skin controls for quicker customization browsing.
- 2026-07-29: Preserved each player's personal reward or forfeit summary when returning from a run to the hub.
- 2026-07-29: Added a structured post-run results panel with score, lines, rewards, best-score progress, close, and quick battle queue actions.
- 2026-07-29: Extracted the post-run results UI into a dedicated client module as the first step toward splitting the large client UI script.
- 2026-07-29: Added server-authored next-cosmetic-unlock hints to the post-run results panel.
- 2026-07-29: Added a cosmetic closet panel with piece/board preview grids, equipped states, locked requirements, and direct equip actions.
- 2026-07-29: Added story chapter intro, success, and failure copy to mission starts, in-run objectives, and post-run results.
- 2026-07-29: Replaced delayed client-side replay sequencing with a server-authoritative `PlayAgain` queue action that only requeues from hub or finished runs.
- 2026-07-29: Extracted client sound cue creation, volume, mute, and playback into a dedicated `SoundController` module.

## Current Priorities

- Expand cosmetic closet into a full shop/inventory flow with earnable inventory, featured items, and clearer purchase-free progression.
- Execute Studio multiplayer stress tests using the diagnostics overlay and fix issues found.
- Continue anti-exploit hardening around server-authoritative economy events and abnormal session lifecycle edge cases.
- Add richer original audio assets and mix testing.
- Expand Story Training into a mission-select presentation with chapter browsing and replay choices.
- Validate compact touch layout in Roblox Studio device emulation.

## Known Issues

- `BlockBlastBattle.rbxl` may be locked if Roblox Studio has it open; build to a day-specific place file instead.
- Rojo plugin connection still needs a live Roblox Studio playtest.
- Two-player battle flow needs Roblox Studio local server testing.
- First-time onboarding and compact battle layout need Studio validation across desktop and mobile screen sizes.
- Current battle board is UI-only; future versions should consider an optional 3D board representation in the arena.

## Technical Debt

- `BlockBlastClient.client.luau` is still large; `ResultPanel.luau`, `CosmeticPanel.luau`, and `SoundController.luau` are the first extractions, and battle board, hub panel, and settings controls should follow.
- Profile save data covers best score, wins, coins, XP, level, Story Stars, core settings, piece skin, and board skin; unlocks are progression-derived, while broader cosmetic inventory still needs persistence.
- Effects are client-side only and need particle polish plus final audio asset replacement.
- Match sessions now support multiple active arenas with hub availability UI, analytics, exploit diagnostics, and Studio diagnostics; production still needs Studio stress execution and richer arena lifecycle tooling.

## Release Readiness

- Status: Prototype.
- Not ready for public release until multiplayer, save retries, mobile UI, moderation/anti-exploit, onboarding, audio, and retention loops are tested in Studio.
