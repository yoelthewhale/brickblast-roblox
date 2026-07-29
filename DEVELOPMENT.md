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

## Current Priorities

- Improve first-time player onboarding.
- Add persistent settings and customization.
- Split matchmaking into isolated match sessions with separate arenas.
- Add sound settings and starter sound effects.
- Expand story mode with missions, goals, dialogue, and rewards.

## Known Issues

- `BlockBlastBattle.rbxl` may be locked if Roblox Studio has it open; build to a day-specific place file instead.
- Rojo plugin connection still needs a live Roblox Studio playtest.
- Two-player battle flow needs Roblox Studio local server testing.
- Current battle board is UI-only; future versions should consider an optional 3D board representation in the arena.

## Technical Debt

- `BlockBlastClient.client.luau` is growing large and should be split into UI modules.
- Profile save data covers best score, wins, coins, XP, and level; settings and customization still need persistence.
- Effects are client-side only and need sound/particle polish.
- Queue system supports one active match; production needs per-match arena sessions.

## Release Readiness

- Status: Prototype.
- Not ready for public release until multiplayer, saves, mobile UI, moderation/anti-exploit, onboarding, audio, and retention loops are tested.
