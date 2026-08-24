# BrickBlast Build Index

## CURRENT GAME TO OPEN

`BlockBlastBattle-Day53.rbxl`

- Source branch: `integrate/day53-combined-experience`
- Source commit: `877c0a0`
- Built: `2026-08-24 12:39:33 -04:00`
- Location: repository root
- Purpose: combined Day53 checkpoint with the approved Deep Board visual direction, the server-authoritative free One More Chance prototype, the Deep Board-painted continue card, simplified Solo hub, and Claude's clear-celebration feedback.

Double-click `BlockBlastBattle-Day53.rbxl` when you want to test the newest
real BrickBlast game.

Important: Day52 was the first Deep Board master build. Day53 is the first
local checkpoint that combines Deep Board with the One More Chance feature and
clear-celebration feedback.

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
historical checkpoints through Day52 now live in `checkpoints/` and are kept
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
| `BlockBlastBattle-Day53.rbxl` | `integrate/day53-combined-experience` at `877c0a0` | Current combined checkpoint: Deep Board, One More Chance, clear celebration, simple hub, and old UI clutter cleanup. |

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
real `BlockBlastBattle-Day*.rbxl` checkpoint, which is currently Day53.

Next real numbered checkpoint: Day54.
