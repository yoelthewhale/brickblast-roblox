# BrickBlast

BrickBlast is a full-screen, stage-based Roblox block puzzle game built with Luau, Rojo, Git, StyLua, and Selene.

The current direction is **Solo first**: tighten the core 8x8 puzzle loop, scoring feel, stage pacing, UI responsiveness, saved progression, and validation workflow before reopening larger modes.

New here? Start with [`BLOCK_BLAST_START_HERE.md`](BLOCK_BLAST_START_HERE.md) for setup, or [`AGENTS.md`](AGENTS.md) if you're working with an AI coding agent on this repo.

## Current Status

- Solo mode is enabled and is the primary development path.
- Battle, Story, and Custom Lab remain disabled behind feature gates.
- In place: smart hand generation, stage progression, cosmetics/shop, an achievements system with lifetime stats, a redeemable-codes system, synced gameplay feedback animations and sound, a full shape roster (including diagonal pieces), and developer tools.
- A headless automated test runner (`scripts/run-tests.luau`, via Lune) covers the pure gameplay-logic modules in `src/shared/game/`. Anything under `src/client/` or `src/server/` still needs a Roblox Studio Play-mode check.
- Not yet supported: mobile/touch layout (piece dragging is currently mouse-only).
- Project management is tracked in GitHub Issues and the **BrickBlast Development** project board.

## Gameplay Features

- 8x8 board with exactly 64 logical cells.
- Three-piece hand/tray block puzzle loop with drag-to-place.
- Row and column clears, with staggered clear animations, score popups, combo pulses, and perfect-clear feedback.
- Stage progression and stage-specific visual transforms.
- Smart but not automatic hand generation, including diagonal (corner-touching, not edge-adjacent) pieces as the hardest to place.
- Tiered achievements and lifetime stats, and a redeemable-codes system.
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
- Lune (headless test runner)
- Git and GitHub Issues/Projects

## Project Structure

- `src/client/ui/` - client UI controllers, panels, visuals, and Solo workspace.
- `src/server/services/` - server-authoritative gameplay, profile/session handling, receipts, rewards, achievements, codes, and developer tools.
- `src/server/world/` - generated hub/world construction.
- `src/shared/game/` - shared rules, config, grid logic, hand generation, achievements, simulation helpers, and pure test modules.
- `docs/` - current rules, setup, and validation docs. `docs/archive/` holds superseded point-in-time snapshots — not current truth.
- `scripts/` - helper scripts, including the headless test runner.
- `tools/` - pinned local CLI tools used by the project.
- `assets/` - generated/approved local UI assets and mockups.

## Safe Validation Commands

Run from the project root:

```powershell
.\tools\stylua.exe src
.\tools\selene.exe src
.\tools\rojo.exe build default.project.json --output BlockBlastBattle-DevSetup.rbxl
.\tools\lune.exe run scripts/run-tests.luau
git diff --check
```

`scripts/run-tests.luau` is a headless runner (via Lune, a standalone Luau runtime) for the pure `*Tests.luau` modules in `src/shared/game/`. It fakes just enough of the Roblox environment — `Vector2`/`Color3`/etc. from Lune's `@lune/roblox`, a `Random.new` polyfill, and a `script.Parent.X`-style require shim — to run those modules outside Studio, and exits non-zero if any module fails. It cannot run anything under `src/client/` or `src/server/`, since those depend on real Roblox services.

## GitHub Project

Roadmap work is managed in the GitHub Project:

**BrickBlast Development** — https://github.com/users/yoelthewhale/projects/1/views/1

Issues are labeled by `type:` (bug/feature/polish/documentation/testing/technical-debt), `area:` (which system), and `priority:`. See [`docs/PROJECT_TRACKER.md`](docs/PROJECT_TRACKER.md) for details.

## Notes

This project must not copy competitor branding, logos, screenshots, or copyrighted assets. Remaining legacy internal names should be renamed deliberately where safe, while preserving compatibility when required.
