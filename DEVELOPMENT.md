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
- 2026-08-01: Mirrored finite-number settings guards on the client before applying theme, UI scale, and sound volume updates.
- 2026-08-01: Built `BlockBlastBattle-Day4.rbxl` after `BlockBlastBattle-Day3.rbxl` was locked by an open Studio session.
- 2026-08-01: Added server-authoritative combo streaks, combo score bonuses, live combo banners, best-combo tracking, and match duration/best-combo result stats.
- 2026-08-01: Added a server-authoritative first-win daily bonus for battle victories or next-chapter story completions, persisted claim dates, hub reminder text, and result-panel bonus feedback.
- 2026-08-01: Added a replayable hub Guide button that reopens the tutorial without resetting saved tutorial completion.
- 2026-08-01: Added a complete first shop vertical slice with Featured, Passes, Cosmetics, and Currency categories, responsive reusable product cards, server-fed item state, loading/owned/equipped/locked/unavailable/error feedback, touch-sized controls, and gamepad focus entry.
- 2026-08-01: Added secure monetization scaffolding with centralized placeholder game pass/developer product IDs, server-validated prompt requests, prompt locks, cached game pass ownership refreshes, post-purchase game pass refresh, and server-only developer product receipt fulfillment.
- 2026-08-01: Hardened developer-product receipts so fulfilled purchase IDs persist inside the player profile in the same durable update that applies currency, avoiding duplicate grants across receipt retries and server restarts.
- 2026-08-01: Added low-volume shop analytics counters for snapshot requests, prompt requests, rejected prompts, completed/cancelled prompts, ownership refreshes, and developer product receipt outcomes.
- 2026-08-01: Documented Creator Dashboard monetization setup in `docs/MONETIZATION_SETUP.md` and kept placeholder IDs at `0` until real Roblox assets exist.
- 2026-08-01: Evaluated React Luau for the shop slice and deferred it because the project has no React/Wally dependencies installed; the production slice instead uses a reusable, state-driven Luau panel architecture compatible with the existing Rojo app.
- 2026-08-01: Built the next place artifact as `BlockBlastBattle-Day6.rbxl`.
- 2026-08-01: Modernized the home hub layout with a wider first-screen panel, larger Battle/Story touch targets, dedicated Shop & Closet action, less cramped settings controls, theme-aware shop entry styling, and gamepad focus when the home panel opens.
- 2026-08-01: Added a centralized server-authoritative cosmetic catalog for piece skins, board skins, line-clear effects, and player titles.
- 2026-08-01: Added persistent cosmetic inventory schema `profile.cosmetics` with owned IDs, equipped IDs by category, default migration, and safe fallback for invalid saved entries.
- 2026-08-01: Connected the shop Cosmetics tab to server-owned catalog snapshots with coin purchase, equip, pass-required, locked, unavailable, preview, owned, and equipped states.
- 2026-08-01: Applied equipped cosmetics to gameplay for piece colors, board theme, line-clear feedback, and in-run player title presentation.
- 2026-08-01: Added `docs/STUDIO_TEST_CHECKLIST.md` covering migration, shop, Marketplace, mobile/gamepad, reduced-motion, and two-player cosmetic validation.
- 2026-08-01: Added centralized low-volume shop analytics for shop opens, tab selection, cosmetic previews, cosmetic purchase attempts/success/failure, cosmetic equips, and gamepass prompt openings.
- 2026-08-01: Added shared `UITheme` design tokens/helpers for panels, cards, text, buttons, and reduced-motion-aware button feedback.
- 2026-08-01: Modernized the shop, results panel, hub shell, battle window, minimized battle dock, tutorial panel, and toast banner with consistent rounded surfaces, strokes, gradients, and cross-input `Activated` controls.
- 2026-08-01: Brought Story Missions and Cosmetic Closet panels onto the shared UI theme with state-aware card strokes and cross-input activation.
- 2026-08-01: Built the next place artifact as `BlockBlastBattle-Day8.rbxl`.

## Current Priorities

- Extract the modernized home/hub interface into a cohesive reusable module instead of continuing to grow `BlockBlastClient.client.luau`.
- Execute Studio multiplayer stress tests using the diagnostics overlay and fix issues found.
- Extract the modernized home/hub interface into a cohesive reusable module instead of continuing to grow `BlockBlastClient.client.luau`.
- Continue anti-exploit hardening around server-authoritative economy events and abnormal session lifecycle edge cases.
- Polish core game feel around line clears, incoming pressure, victory/defeat, and reward reveals.
- Add quest or challenge presentation that builds on the first-win daily bonus without creating exploitable reward spam.
- Add richer original audio assets and mix testing.
- Expand Story Training with more mission types, longer chapter arcs, and better hub-world story signposting.
- Validate compact touch layout in Roblox Studio device emulation.

## Known Issues

- `BlockBlastBattle.rbxl` may be locked if Roblox Studio has it open; build to a day-specific place file instead.
- Rojo plugin connection still needs a live Roblox Studio playtest.
- Two-player battle flow needs Roblox Studio local server testing.
- First-time onboarding and compact battle layout need Studio validation across desktop and mobile screen sizes.
- Current battle board is UI-only; future versions should consider an optional 3D board representation in the arena.
- Monetization IDs are intentionally `0`; real purchase prompt testing is blocked until Creator Dashboard game passes and developer products exist.
- Developer product receipt persistence now uses profile `fulfilledPurchaseIds`; it still needs live DataStore failure testing before any real currency products are enabled.

## Technical Debt

- `BlockBlastClient.client.luau` is still large; `ResultPanel.luau`, `CosmeticPanel.luau`, `SoundController.luau`, `StoryPanel.luau`, and `ShopPanel.luau` are the first extractions, and battle board, hub panel, and settings controls should follow.
- Profile save data covers best score, wins, coins, XP, level, Story Stars, first-win daily claim date, core settings, piece skin, and board skin; numeric profile and settings values are sanitized on both server and client, while broader cosmetic inventory still needs persistence.
- Shop product definitions and cosmetic ownership are centralized; cosmetic presets still need a real UI and server validation flow.
- Extra Preset Slots Pass remains marked unavailable while its real preset UI/server save flow is unfinished.
- Effects are client-side only and need particle polish plus final audio asset replacement.
- Match sessions now support multiple active arenas with hub availability UI, analytics, exploit diagnostics, and Studio diagnostics; production still needs Studio stress execution and richer arena lifecycle tooling.

## Release Readiness

- Status: Prototype.
- Not ready for public release until multiplayer, save retries, mobile UI, monetization IDs/purchase flows, moderation/anti-exploit, onboarding, audio, and retention loops are tested in Studio.

## Session Update - 2026-08-01 Shop Slice

### Completed

- Built `src/client/ui/ShopPanel.luau`, a reusable state-driven shop panel with category tabs, product-card rendering, responsive scaling, touch-friendly activation buttons, and gamepad focus on open.
- Integrated the shop into `src/client/ui/BlockBlastClient.client.luau` through the existing hub cosmetics entry, while preserving the old closet as the equip destination for progression cosmetics.
- Added `src/shared/game/Config.luau` monetization definitions for VIP Pass, Deluxe Cosmetics Pass, Extra Preset Slots Pass, Supporter Pass, and three placeholder coin developer products.
- Added `BlockBlastRemotes.Shop` in `src/server/services/GameServer.server.luau` with validated actions, prompt throttling, prompt locks, placeholder rejection, cached ownership checks, post-purchase refresh, and server-only developer product receipt fulfillment.
- Added dormant server reward hooks for owned pass benefits. Because every marketplace ID is `0`, no player can currently receive paid benefits accidentally.
- Added shop analytics counters to the existing server diagnostics data model.
- Added `docs/MONETIZATION_SETUP.md` with the Creator Dashboard steps and ID replacement rules.
- Formatted with Stylua, linted with Selene, and built `BlockBlastBattle-Day6.rbxl`.

### Current State

- The shop is a visible playable UI slice, but real Roblox purchase prompts remain intentionally unavailable until dashboard IDs replace the `0` placeholders.
- React Luau was deferred. The project currently has empty Wally dependencies and no React mounting/runtime pattern, so introducing React during this monetization pass would have increased migration risk without improving this release checkpoint.
- The client never grants currency, cosmetics, XP, or ownership.
- The server owns entitlement checks, prompt approval, receipt fulfillment, and post-purchase refresh.

### Recommended Next Priorities

1. Extract and modernize the hub/home UI.
   This is now the weakest player-facing area and will reduce the oversized main client script.
2. Add a true cosmetic inventory/equip model.
   The shop can display owned/equipped/locked states, but cosmetics are still derived from progression instead of an inventory table that can handle pass entitlements later.
3. Run Roblox Studio purchase and multiplayer tests after real IDs exist.
   The code builds locally, but MarketplaceService and multiplayer edge cases need Studio validation.
4. Improve mobile/gamepad navigation across all modal panels.
   The shop has focus entry and touch-sized buttons, but the older panels should be brought up to the same standard.

### Technical Debt

- Developer product receipt handling has persistent and in-memory receipt tracking, but real product enablement still requires live retry/failure testing.
- The shop UI destroys/recreates low-volume cards on refresh. This is acceptable for the current item count but could be pooled if the catalog grows.
- The existing hub controls are still laid out manually in the main client script.

### Ideas

- Add a featured rotation timer once the shop has real cosmetic inventory.
- Add preview thumbnails for each cosmetic card.
- Add a non-monetized daily deals area using earnable coins only.
- Add a VIP/supporter nameplate in the hub after game pass IDs are active.

### Release Readiness

- Estimate: prototype advancing toward alpha, roughly 35% of the way to public Roblox release.
- Biggest remaining blockers: Studio multiplayer validation, real Creator Dashboard monetization assets, mobile testing, and a polished onboarding/home flow.
- Biggest gameplay weakness: the core battle loop still needs more tactile arena feedback and pacing tests.
- Biggest polish opportunity: a modern home screen that clearly routes players into Battle, Story, Shop, Closet, and Settings.
- Biggest technical risk: Marketplace receipt and entitlement behavior must be tested with real Roblox services before any paid products are enabled.

## Session Update - 2026-08-01 Home Slice

### Completed

- Expanded the hub panel into a clearer home screen in `src/client/ui/BlockBlastClient.client.luau`.
- Enlarged Battle and Story actions for mouse/touch use and moved secondary settings into a cleaner two-column layout.
- Made Shop & Closet a dedicated primary home action instead of hiding shop access behind cosmetic hint copy.
- Added gamepad focus to the Battle queue button when the home panel opens.
- Updated home scaling to use one `HUB_SIZE` constant so future extraction has a cleaner boundary.
- Rebuilt `BlockBlastBattle-Day6.rbxl` after the home UI changes.

### Current State

- Home is visibly cleaner and easier to scan, but its implementation still lives inside the oversized main client script.
- The next clean architectural step is to extract this home surface into a `HomePanel` module similar to `ShopPanel`, `StoryPanel`, and `CosmeticPanel`.
- Roblox Studio device emulation is still needed to confirm safe-area behavior on phones and tablets.

### Recommended Next Priorities

1. Extract `HomePanel.luau`.
   The layout is now stable enough to move without redesigning it at the same time.
2. Add a true cosmetic inventory/equip model.
   Shop and closet are connected, but progression-derived cosmetics need a future-proof ownership layer.
3. Studio-test mobile and gamepad flow.
   The code validates locally, but Roblox input behavior needs device validation.

## Session Update - 2026-08-01 Cosmetic Inventory Slice

### Completed

- Added centralized cosmetic catalog definitions in `src/shared/game/Config.luau`.
- Added `profile.cosmetics` persistence with `owned`, `equipped`, placeholder `presets`, and `activePreset` fields.
- Migrated old saved piece/board settings into equipped cosmetic IDs when valid.
- Added safe defaults for fresh players and invalid saved cosmetic recovery.
- Made the shop Cosmetics tab use server snapshots instead of client-derived progression state.
- Added server-validated `PurchaseCosmetic` and `EquipCosmetic` shop actions.
- Added coin purchases for `BOARD_SUGAR` and `CLEAR_RIPPLE` with rollback on save failure.
- Added preview callbacks that let the client inspect piece/board visuals without granting or saving ownership.
- Applied equipped piece, board, line-clear, and title cosmetics to gameplay presentation.
- Added `docs/STUDIO_TEST_CHECKLIST.md`.

### Current State

- Cosmetics are now server-authoritative for ownership and equip.
- Existing quick piece/board buttons are still present, but server settings sanitization now checks inventory ownership and progression through the same catalog rules.
- Presets are only schema placeholders. The Extra Preset Slots Pass is intentionally unavailable until a real preset UI and validation flow exists.
- Studio validation has not been performed in this run.

### Recommended Next Priorities

1. Extract `HomePanel.luau`.
   The home UI is still the largest unrelated responsibility inside the main client script.
2. Complete cosmetic presets.
   The profile schema has placeholders, but slots, save/select UI, and Extra Preset Slots validation are not done.
3. Add a richer selected-item details area to the shop.
   Cards now work, but a details pane would improve preview and purchase confidence.

## Session Update - 2026-08-01 Shop Analytics Slice

### Completed

- Added validated `Shop` remote analytics tracking for a fixed allowlist of low-volume event names.
- Added counters for shop opens, tab selections, cosmetic previews, cosmetic purchase attempts/success/failure, cosmetic equips, and gamepass prompt openings.
- Emitted analytics from `ShopPanel.luau` without logging hover activity, personal information, or sensitive purchase data.
- Kept analytics outside the shop action cooldown so tracking cannot throttle snapshot, purchase, or equip requests.

### Current State

- Analytics are still in-memory diagnostic counters exposed through the existing server analytics model.
- Production analytics export is not connected yet.

## Session Update - 2026-08-01 UI Foundation Slice

### Completed

- Added `src/client/ui/UITheme.luau` with reusable design tokens and helpers for panel/card/button/text styling.
- Applied the shared visual system to `ShopPanel.luau`, including polished product cards, category tabs, modal shell, and button feedback.
- Modernized `ResultPanel.luau` with clearer reward and summary cards, larger action targets, and shared styling.
- Applied consistent styling to the hub shell, tutorial panel, toast banner, active battle window, minimized battle dock, and major home/gameplay buttons in `BlockBlastClient.client.luau`.
- Converted the main UI and updated shop/results panels from mouse-only `MouseButton1Click` handlers to Roblox `Activated` handlers for better mouse, touch, keyboard, and gamepad support.
- Formatted with Stylua, linted with Selene, and built `BlockBlastBattle-Day8.rbxl`.

### Current State

- The main UI is visibly more coherent and keeps the existing shop, cosmetics, gameplay, persistence, and monetization behavior intact.
- `BlockBlastClient.client.luau` still owns too much UI construction, but the new theme module gives future extractions a shared styling foundation.
- Roblox Studio device-emulation testing has not been performed in this run.

### Recommended Next Priorities

1. Extract the hub/home UI into `HomePanel.luau`.
   The surface is now visually stable enough to move into a cohesive module.
2. Apply the shared theme to `CosmeticPanel.luau` and `StoryPanel.luau`.
   These are now the most visually inconsistent modal panels.
3. Add more explicit gamepad focus paths between hub, shop, story, cosmetics, and battle controls.
   `Activated` support is improved, but focus order still needs deliberate Studio validation.

## Session Update - 2026-08-01 Modal Consistency Slice

### Completed

- Updated `src/client/ui/CosmeticPanel.luau` to use the shared `UITheme` panel, text, button, and feedback helpers.
- Added state-aware cosmetic card strokes so equipped, unlocked, and locked cards read more clearly without changing unlock logic.
- Updated `src/client/ui/StoryPanel.luau` to use the shared modal shell, text styles, button feedback, and state-aware mission card strokes.
- Converted Story and Cosmetic panel actions from `MouseButton1Click` to `Activated` for broader input support.
- Formatted with Stylua, linted with Selene, and rebuilt `BlockBlastBattle-Day8.rbxl`.

### Current State

- All major player-facing modal panels now share one visual system.
- Gameplay, shop, story, cosmetics, persistence, and monetization behavior remain unchanged aside from UI activation compatibility.
- Studio device-emulation and live gamepad focus-order testing are still needed.

### Recommended Next Priorities

1. Extract `HomePanel.luau`.
   This is now the biggest architecture win because the visual language is centralized and the home surface is still embedded in the large client script.
2. Add deliberate focus ordering/default selections to every modal panel.
   Buttons activate across inputs now, but gamepad/keyboard navigation should feel intentional.

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
