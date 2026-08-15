# BrickBlast

BrickBlast is a full-screen, stage-based Roblox block puzzle game built with Luau, Rojo, Git, StyLua, and Selene.

The current direction is **Solo first**: tighten the core 8x8 puzzle loop, scoring feel, stage pacing, UI responsiveness, saved progression, and validation workflow before reopening larger modes.

## Current Status

- Solo mode is enabled and is the primary development path.
- Battle, Story, and Custom Lab remain disabled behind feature gates.
- The current clean checkpoint is Day43 on commit `6e8f6b86015b862fe623ceb59b000512e65daa84`.
- Smart hand generation, stage progression, developer tools, full-screen stage transformations, difficulty balancing, and UI cleanup are in place.
- Project management is tracked in GitHub Issues and the **BrickBlast Development** project board.

## Gameplay Features

- 8x8 board with exactly 64 logical cells.
- Three-piece hand/tray block puzzle loop.
- Row and column clears.
- Stage progression and stage-specific visual transforms.
- Smart but not automatic hand generation.
- Combo, perfect-clear, score, and progression systems under active development.
- Server-authoritative gameplay and developer tools.

## Important 8x8 Invariant

The logical board is exactly `Config.BoardSize` by `Config.BoardSize`, currently `8 x 8`.

The visible PC board must show exactly 64 direct cell buttons under `BoardGridContainer`. Do not add decorative or helper GUI objects as direct children of that container. Board placement math must use the board's current `AbsolutePosition` and `AbsoluteSize`.

## Technology Stack

- Roblox / Luau
- Rojo
- Rokit
- Wally
- StyLua
- Selene
- Git and GitHub Issues/Projects

## Project Structure

- `src/client/ui/` - client UI controllers, panels, visuals, and Solo workspace.
- `src/server/services/` - server-authoritative gameplay, profile/session handling, receipts, rewards, and developer tools.
- `src/server/world/` - generated hub/world construction.
- `src/shared/game/` - shared rules, config, grid logic, hand generation, simulation helpers, and pure test modules.
- `docs/` - planning notes, audits, validation checklists, and design references.
- `tools/` - pinned local CLI tools used by the project.
- `assets/` - generated/approved local UI assets and mockups.

## Safe Validation Commands

Run from the project root:

```powershell
.\tools\stylua.exe src
.\tools\selene.exe src
.\tools\rojo.exe build default.project.json --output BlockBlastBattle-DevSetup.rbxl
git diff --check
```

There is no established automated Luau test runner yet. Pure test modules exist, but a reliable project-local runner is tracked as roadmap work.

## GitHub Project

Roadmap work is managed in the private GitHub Project:

`BrickBlast Development`

## Notes

This project must not copy competitor branding, logos, screenshots, or copyrighted assets. Remaining legacy internal names should be renamed deliberately where safe, while preserving compatibility when required.
