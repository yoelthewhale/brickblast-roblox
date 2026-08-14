# BrickBlast Agent Guide

## Current Direction

BrickBlast is currently a solo-first Roblox block-puzzle game. Prioritize the PC solo puzzle workspace, core rules, puzzle feel, and trustworthy saved progression before reopening mobile polish, multiplayer, Battle, Story, or Custom Lab expansion.

The planned identity is fast-flowing puzzle gameplay with smart but not automatic hands, satisfying combos, Perfect Clears, stage progression, and cosmetics called Themes.

## Important Entry Points

- `src/client/ui/BlockBlastClient.client.luau`: main local client controller and current PC solo puzzle UI orchestration. This file is oversized and should be reduced gradually through focused extractions.
- `src/client/ui/ArcadeUI.luau`: arcade visual helpers for panels, board cells, buttons, cards, and UI polish.
- `src/client/ui/HUDController.luau`: hub HUD and menu button controller.
- `src/client/ui/MenuController.luau`: reusable menu shell.
- `src/client/ui/ShopPanel.luau`: shop/gamepass/product presentation and purchase prompt client.
- `src/client/ui/CosmeticPanel.luau`: cosmetics/theme inventory UI.
- `src/client/ui/ResultPanel.luau`: solo/result presentation.
- `src/client/ui/UITheme.luau`: shared theme values for the older HUD/menu system.
- `src/client/ui/UIAssets.luau`: centralized Roblox image asset IDs. Keep unapproved or rejected art out of upload candidates.
- `src/server/services/GameServer.server.luau`: server-authoritative gameplay, profiles, receipts, remotes, session lifecycle, rewards, analytics, and disabled legacy modes. This file is oversized.
- `src/server/world/HubBuilder.luau`: generated toybox hub, spawn, prompts, and optional disabled Battle/Story routes.
- `src/shared/game/Blocks.luau`: piece definitions, colors, rotation, and random hand creation.
- `src/shared/game/Grid.luau`: reusable board rules: create, clone, can place, place, clear lines, move detection, and garbage rows.
- `src/shared/game/Config.luau`: board size, scoring, rewards, monetization placeholders, cosmetics, missions, and unlock data.
- `src/shared/game/ExperienceConfig.luau`: solo-first feature gates. At this checkpoint Solo is enabled; Battle, Story, and Custom Lab are disabled.

## Validation Commands

Run from the project root:

```powershell
.\tools\stylua.exe src
.\tools\selene.exe src
.\tools\rojo.exe build default.project.json --output BlockBlastBattle-DevSetup.rbxl
git diff --check
```

There is no established automated test runner yet. Do not invent a passing test command. A future TestEZ setup is reasonable only after extracting pure gameplay modules and getting approval to add the dependency.

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
3. Split PC puzzle workspace UI from `BlockBlastClient.client.luau` after preserving drag, resize, clamping, board input, scoring display, result actions, and reduced-motion behavior.
4. Remove disabled Battle/Story code only after deciding whether those modes are permanently out of scope.
5. Add automated tests around `Grid`, `Blocks`, and future hand generation before changing puzzle difficulty.

