# BrickBlast Agent Guide

## Current Direction

BrickBlast is currently a solo-first Roblox block-puzzle game. Prioritize the PC solo puzzle workspace, core rules, puzzle feel, and trustworthy saved progression before reopening mobile polish, multiplayer, Battle, Story, or Custom Lab expansion.

The planned identity is fast-flowing puzzle gameplay with smart but not automatic hands, satisfying combos, Perfect Clears, stage progression, and cosmetics called Themes.

## Important Entry Points

- `src/client/ui/BlockBlastClient.client.luau`: main local client controller and current PC solo puzzle UI orchestration. This file is oversized and should be reduced gradually through focused extractions. It is also a **single top-level Luau chunk close to the compiler's 200-local-register limit** — new top-level `local` declarations (including local functions) should be attached to the existing `day43Ui` table instead of declared fresh, or the whole script can fail to compile with no obvious error beyond "Out of local registers" in the Output window and the entire HUD silently not rendering.
- `src/client/ui/ArcadeUI.luau`: arcade visual helpers for panels, board cells, buttons, cards, animations (score popups, combo pulses, staggered line clears, perfect-clear flash), and UI polish.
- `src/client/ui/HUDController.luau`: hub HUD and menu button controller.
- `src/client/ui/MenuController.luau`: reusable menu shell.
- `src/client/ui/ShopPanel.luau`: shop/gamepass/product presentation and purchase prompt client.
- `src/client/ui/CosmeticPanel.luau`: cosmetics/theme inventory UI.
- `src/client/ui/ResultPanel.luau`: solo/result presentation.
- `src/client/ui/StoryPanel.luau`: story mission UI (Story mode is disabled, but the panel still exists).
- `src/client/ui/SoundController.luau`: client sound cue playback.
- `src/client/ui/UITheme.luau`: shared theme values for the older HUD/menu system.
- `src/client/ui/UIAssets.luau`: centralized Roblox image asset IDs. Keep unapproved or rejected art out of upload candidates.
- `src/server/services/GameServer.server.luau`: server-authoritative gameplay, profiles, receipts, remotes, session lifecycle, rewards, analytics, achievements, redeemable codes, and disabled legacy modes. This file is oversized.
- `src/server/world/HubBuilder.luau`: generated toybox hub, spawn, prompts, and optional disabled Battle/Story routes.
- `src/shared/game/Blocks.luau`: piece definitions, colors, rotation, and random hand creation.
- `src/shared/game/Grid.luau`: reusable board rules: create, clone, can place, place, clear lines, move detection, and garbage rows.
- `src/shared/game/Config.luau`: board size, scoring, rewards, monetization placeholders, cosmetics, missions, and unlock data.
- `src/shared/game/ExperienceConfig.luau`: solo-first feature gates. At this checkpoint Solo is enabled; Battle, Story, and Custom Lab are disabled.
- `src/shared/game/Achievements.luau`: pure logic for the tiered achievements system (definitions + threshold-crossing detection). Covered by `AchievementsTests.luau`.

## Validation Commands

Run from the project root:

```powershell
.\tools\stylua.exe src
.\tools\selene.exe src
.\tools\rojo.exe build default.project.json --output BlockBlastBattle-DevSetup.rbxl
.\tools\lune.exe run scripts/run-tests.luau
git diff --check
```

`scripts/run-tests.luau` is a real, working automated test runner (via Lune, a standalone Luau runtime) for every `src/shared/game/*Tests.luau` module. It cannot test anything under `src/client/` or `src/server/` — those depend on real Roblox services and still require a Studio Play-mode check. `Grid.luau`, `Blocks.luau`, `Config.luau`, and `ExperienceConfig.luau` don't have dedicated test files yet (they're only exercised indirectly through the modules that require them) — adding those directly would close a real gap.

## Workflow Rules

- Work one focused checkpoint and one focused commit at a time.
- Never overwrite earlier `.rbxl` builds. Use a new requested filename or the next unused Day number.
- Never claim Roblox Studio Play testing unless Studio MCP actually ran it or Yoel explicitly reports the result.
- Do not publish, purchase assets, change Creator Dashboard settings, or enable production DataStore access without explicit approval.
- Preserve server authority for gameplay, DataStores, receipts, settings, cosmetics, rewards, and ownership.
- Preserve disabled Battle/Story behavior until a checkpoint explicitly reactivates or removes it.
- Treat PC gameplay as the primary path. Mobile-specific redesign comes later unless requested.
- Keep generated art, screenshots, rejected icon packs, and upload manifests clearly separated from source-controlled gameplay code.

## Locked Board Invariant

- The logical board is exactly `Config.BoardSize` by `Config.BoardSize`; currently `8 x 8`.
- The visible PC board must show exactly 64 direct cell buttons under `BoardGridContainer`.
- Do not add decorative or helper GuiObjects as direct children of `BoardGridContainer`.
- Board placement math must use the board's current `AbsolutePosition` and `AbsoluteSize`, so dragging and proportional resizing do not break hover or placement.
- `BoardGridContainer.ClipsDescendants` is a safety boundary, not a substitute for correct grid sizing.

## Safe Cleanup Order

1. Extract pure rule helpers from `GameServer.server.luau` only when behavior is covered by source checks or tests.
2. Move solo hand generation to a shared/server module before adding smart randomness or stage progression.
3. Split PC puzzle workspace UI from `BlockBlastClient.client.luau` after preserving drag, resize, clamping, board input, scoring display, result actions, and reduced-motion behavior. This is no longer just a cleanliness goal — the file has already hit Luau's 200-local-register ceiling once (see Entry Points above), so it should shrink rather than keep growing.
4. Remove disabled Battle/Story code only after deciding whether those modes are permanently out of scope.
5. `HandGenerator` now has test coverage (`HandGeneratorTests.luau`, run via `scripts/run-tests.luau`). `Grid` and `Blocks` still don't — add tests for those before changing puzzle difficulty.

