# BrickBlast Build Index

## CURRENT GAME TO OPEN

`BlockBlastBattle-Day60.rbxl`

- Source branch: `integrate/day53-combined-experience`
- Source code commit: `f70fa2a`
- Built: `2026-08-26 15:46:40 -04:00`
- Location: repository root
- Purpose: current combined checkpoint with Day59 plus Claude's boot loading screen and gem block style work. It keeps the chosen Day58 solid color fix, line-clear drag preview, clear celebration feedback, trimmed shape set, difficulty tuning, and simple hub while adding the boot spinner and selectable block styles.

Double-click `BlockBlastBattle-Day60.rbxl` when you want to test the newest
real BrickBlast game.

Important: Day52 was the first Deep Board master build. Day53 is the first
local checkpoint that combines Deep Board with the One More Chance feature and
clear-celebration feedback. Day54 adds Claude's new clear-line glow and
approved shape-set cleanup on top without overwriting Day53. Day55 adds the
deeper room tuning and HUD cleanup on top without overwriting Day54. Day56
adds the difficulty tuning and Spicy shot clock on top without overwriting
Day55. Day57 fixes the missing-UI risk found while testing Day56. Day58 fixes
the block-color striping bug so each piece stays one solid color. Day59 adds
the line-clear drag preview on top of Day58 without replacing the chosen color
fix. Day60 combines the remaining Claude boot/loading and gem-block style work
on top of the organized Day59 base.

## Folder Layout

| Location | Purpose |
| --- | --- |
| `src/` | Active Roblox source code. |
| `assets/ui/bubblegum-production/` | Legacy production UI art package; only hue-neutral/reused assets should survive the Deep Board pivot. |
| `docs/` | Current documentation, with older material under `docs/archive/`. |
| `scripts/` | Project automation scripts. |
| `tools/` | Local tool binaries used by validation/build tasks. |
| `checkpoints/` | Historical permanent `.rbxl` Day snapshots. |
| `test-builds/` | Temporary feature/test `.rbxl` builds. |
| `generated/inspection-builds/` | Generated `.rbxlx` inspection artifacts. |
| `logs/` | Local Rojo serve logs. |

## Historical Checkpoints

Most old `BlockBlastBattle*.rbxl` snapshots were moved from the root into:

`checkpoints/`

They were not renamed or deleted. They are ignored generated artifacts and are
kept for comparison/history.

The repository root should contain only the current numbered checkpoint. Recent
historical checkpoints through Day59 now live in `checkpoints/` and are kept
for comparison/history.

## Recent Root Checkpoints

| Build | Source | Purpose |
| --- | --- | --- |
| `BlockBlastBattle-Day46.rbxl` | `master` at `6bebe23` | Synced master after #122/#123; previous documented current build. |
| `BlockBlastBattle-Day47.rbxl` | local feature work | Rejected UI asset cleanup and/or simple Solo hub work; kept for history, not current testing. |
| `BlockBlastBattle-Day48.rbxl` | local feature work + `origin/master` at `2c9022b` | Simple Solo hub plus Claude's left-nav HUD slab fix. |
| `BlockBlastBattle-Day49.rbxl` | `feature/one-more-chance-free-prototype` | Free One More Chance Solo prototype. |
| `BlockBlastBattle-Day50.rbxl` | `feature/one-more-chance-free-prototype` | Day49 plus reviewed responsive One More Chance panel and Solo end-flow fix. |
| `BlockBlastBattle-Day51.rbxl` | `feature/one-more-chance-free-prototype` | Reference-style One More Chance hero card. Superseded visually by Day52 until the feature branch is rebased onto Deep Board. |
| `BlockBlastBattle-Day52.rbxl` | `master` at `15b080c` | First Deep Board master build. Historical comparison build. |
| `BlockBlastBattle-Day53.rbxl` | `integrate/day53-combined-experience` at `877c0a0` | Combined checkpoint: Deep Board, One More Chance, clear celebration, simple hub, and old UI clutter cleanup. |
| `BlockBlastBattle-Day54.rbxl` | `integrate/day53-combined-experience` at `7d91543` | Day53 plus clear-line glow and the approved connected shape set. |
| `BlockBlastBattle-Day55.rbxl` | `integrate/day53-combined-experience` at `6f01bc9` | Day54 plus deeper room tuning and HUD cleanup. |
| `BlockBlastBattle-Day56.rbxl` | `integrate/day53-combined-experience` at `0e5ce37` | Day55 plus stronger difficulty separation, fair-hand tests, and Spicy shot clock. Superseded by Day57 after Yoel found the UI could disappear. |
| `BlockBlastBattle-Day57.rbxl` | `integrate/day53-combined-experience` at `9886bc7` | Day56 plus the UI startup/F8 inspection rescue. Historical comparison build after Day58. |
| `BlockBlastBattle-Day58.rbxl` | `integrate/day53-combined-experience` at `f4a615a` | Historical checkpoint: Day57 plus solid Deep Board piece colors across generation, tray previews, ghost previews, and placed board cells. |
| `BlockBlastBattle-Day59.rbxl` | `integrate/day53-combined-experience` at `cf97695` | Historical checkpoint: Day58 plus line-clear drag preview for rows/columns that would disappear after a valid placement. |
| `BlockBlastBattle-Day60.rbxl` | `integrate/day53-combined-experience` at `f70fa2a` | Current checkpoint: Day59 plus Claude's boot loading screen and selectable gem/block style work. |

Naming convention: real numbered checkpoints use
`BlockBlastBattle-DayNN.rbxl` with the hyphen. `BrickBlast-Day50-LatestTest.rbxl`
was an accidental temporary alias and is not a valid numbered checkpoint.

## Temporary Test Builds

Feature/test builds live in:

`test-builds/`

Examples:

- `BlockBlastBattle-GamepadFocus.rbxl`
- `BlockBlastBattle-DifficultyCurve.rbxl`
- `BlockBlastBattle-InitialSyncTimeout.rbxl`
- `BlockBlastBattle-BubblegumAssets.rbxl`
- `BlockBlastBattle-BubblegumAssets-Uploaded.rbxl`
- `BrickBlast-LatestTest.rbxl`
- `BrickBlast-StudioTest.rbxl`

`BrickBlast-Day50-LatestTest.rbxl` was an accidental local alias, not a real
checkpoint. It now lives in `test-builds/` and should be ignored for normal
testing.

## Checkpoint Rule

Do not invent Day numbers. The next Day number comes from the highest existing
real `BlockBlastBattle-Day*.rbxl` checkpoint, which is currently Day60.

Next real numbered checkpoint: Day61.
