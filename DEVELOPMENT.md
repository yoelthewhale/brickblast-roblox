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
- 2026-07-29: Added battle sudden death with server-owned pressure rows, warning banners, red timer state, and diagnostics counters.
- 2026-07-29: Added a Story Missions panel with recent chapter browsing, replay access for completed chapters, locked upcoming chapter previews, and server-validated selected chapter starts.
- 2026-07-29: Hardened Story Stars so replayed chapters can earn base rewards but cannot farm additional progression stars.
- 2026-07-29: Hardened profile persistence by clamping loaded/saved leaderstat values, rejecting invalid numeric profile data, and surfacing sanitized-field counts in Studio diagnostics.
- 2026-08-01: Hardened server settings sanitization so numeric settings reject NaN/infinite values before clamp/floor handling.
- 2026-08-01: Built `BlockBlastBattle-Day4.rbxl` after `BlockBlastBattle-Day3.rbxl` was locked by an open Studio session.

## Current Priorities

- Execute Studio multiplayer stress tests using the diagnostics overlay and fix issues found.
- Continue anti-exploit hardening around server-authoritative economy events and abnormal session lifecycle edge cases.
- Expand cosmetic closet into a full shop/inventory flow with earnable inventory, featured items, and clearer purchase-free progression.
- Add richer original audio assets and mix testing.
- Expand Story Training with more mission types, longer chapter arcs, and better hub-world story signposting.
- Validate compact touch layout in Roblox Studio device emulation.

## Known Issues

- `BlockBlastBattle.rbxl` may be locked if Roblox Studio has it open; build to a day-specific place file instead.
- Rojo plugin connection still needs a live Roblox Studio playtest.
- Two-player battle flow needs Roblox Studio local server testing.
- First-time onboarding and compact battle layout need Studio validation across desktop and mobile screen sizes.
- Current battle board is UI-only; future versions should consider an optional 3D board representation in the arena.

## Technical Debt

- `BlockBlastClient.client.luau` is still large; `ResultPanel.luau`, `CosmeticPanel.luau`, and `SoundController.luau` are the first extractions, and battle board, hub panel, and settings controls should follow.
- Profile save data covers best score, wins, coins, XP, level, Story Stars, core settings, piece skin, and board skin; numeric profile and settings values are sanitized, while broader cosmetic inventory still needs persistence.
- Effects are client-side only and need particle polish plus final audio asset replacement.
- Match sessions now support multiple active arenas with hub availability UI, analytics, exploit diagnostics, and Studio diagnostics; production still needs Studio stress execution and richer arena lifecycle tooling.

## Release Readiness

- Status: Prototype.
- Not ready for public release until multiplayer, save retries, mobile UI, moderation/anti-exploit, onboarding, audio, and retention loops are tested in Studio.

## Session Handoff - 2026-07-29

### Completed

- Finished the in-flight Story Missions feature and left it fully wired into the hub.
- Added `src/client/ui/StoryPanel.luau`, a reusable client UI module that lists four nearby story chapters: recently completed replay options, the next playable chapter, and a locked upcoming preview.
- Updated `src/client/ui/BlockBlastClient.client.luau` to require `StoryPanel`, open it from the hub Story button, refresh it from hub state, and hide it when a run starts.
- Updated `src/server/services/GameServer.server.luau` so story runs accept a requested chapter, validate that chapter on the server, expose `storyMissions` in hub state, and prevent replayed chapters from awarding extra Story Stars.
- Preserved the existing tutorial `Try Story` shortcut as a quick-start path into the next unlocked story chapter.
- Completed final persistence hardening: `GameServer.server.luau` now clamps profile integers to explicit bounds, rejects NaN/infinite/bad profile values, sanitizes outgoing save payloads, and reports sanitized-field counts through hub analytics.
- Updated `BlockBlastClient.client.luau` Studio diagnostics to show `Profile L/S/Sanitized` so corrupt profile cleanup is visible during playtests.
- Latest clean build is `BlockBlastBattle-Day4.rbxl`; Day 3 may remain locked if Studio has it open.

### Current State

- The project is stable at a clean stopping point after the Story Missions panel work.
- No intentionally partial code remains from this session.
- The story mission list is intentionally compact: it shows a small rolling window around player progress instead of every possible repeated chapter.
- Story replay currently grants normal score-based coins/XP but only awards the bonus Story Star and completion bonus for the next unbeaten chapter.
- Studio/live validation is still required for the new modal UI interactions, ProximityPrompt story start path, and DataStore-backed Story Stars reload behavior.
- No partially completed features remain from the final persistence-hardening task.

### Recommended Next Priorities

1. Run Roblox Studio local server playtests.
   This is the biggest release blocker because matchmaking, arena isolation, rewards, replay, sudden death, and story selection all need proof in real multiplayer clients.
2. Validate mobile and small-screen UI.
   The game depends heavily on UI board interaction; mobile layout failures would immediately hurt first-time players.
3. Continue server-authoritative economy hardening.
   Rewards, cosmetics, replay, and story progression now have more paths, so abnormal lifecycle tests should come before adding monetization or inventory.
4. Improve the hub environment and signposting.
   Players need to understand battle queue, story missions, cosmetics, and settings within the first 60 seconds.
5. Add original audio polish and mix controls.
   Current cue IDs are placeholders suitable for prototype feedback, not final release polish.
6. Expand story content and retention loops.
   The mission framework works, but the campaign needs more objective variety and reasons to return.

### Technical Debt

- `BlockBlastClient.client.luau` remains large despite extracting `ResultPanel`, `CosmeticPanel`, `SoundController`, and `StoryPanel`.
- Story missions are still static config data and repeat in a simple cycle after the current set.
- Cosmetic unlocks are progression-derived; there is no true owned inventory, shop rotation, or purchase-free collection flow yet.
- Client effects are still mostly UI tweens; particle/audio polish should be centralized before launch.
- Analytics are in-memory Studio diagnostics only, not a production analytics pipeline.

### Ideas

- Add a mission map or chapter path in the hub instead of only a modal list.
- Add daily/weekly non-monetized challenges that use the story objective system.
- Add a practice sandbox where players can freely test block shapes without rewards.
- Add arena visual themes tied to board skins or player level.
- Add accessibility presets for color contrast, motion, and larger board cells.
- Add post-match commendations such as `Most Lines Cleared`, `Clutch Finish`, or `Clean Board`.

### Release Readiness

- Estimate: early prototype, roughly 25-30% of the way to a public Roblox release.
- Biggest blockers: Studio multiplayer validation, mobile playability, persistence confidence, moderation/anti-exploit coverage, and content depth.
- Biggest gameplay weaknesses: battle pacing still needs hands-on tuning, story content is short, and the board exists only as UI rather than a more embodied arena experience.
- Biggest polish opportunities: hub visual identity, final sound design, transitions, particles, thumbnails/icons, and better first-session onboarding.
- Biggest technical risks: server session lifecycle edge cases, DataStore behavior under failure, replay/reward duplication paths, and UI scaling across Roblox devices.

### Final Task Files Modified

- `src/server/services/GameServer.server.luau`
- `src/client/ui/BlockBlastClient.client.luau`
- `DEVELOPMENT.md`

### Single Highest-Priority Next Task

- Run the Roblox Studio local server stress-test checklist in `docs/MULTIPLAYER_STRESS_TEST.md`.
  This should happen next because the code now has enough matchmaking, rewards, persistence, story selection, and sudden-death behavior that real multi-client validation is more valuable than another local-only feature.
