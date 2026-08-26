# BrickBlast Build Index

## CURRENT GAME TO OPEN

`BlockBlastBattle-Day52.rbxl`

- Current master SHA: `15b080c`
- Built: `2026-08-23 14:15:00 -04:00`
- Location: repository root
- Purpose: current local checkpoint built from synced `origin/master`; first build with the approved Deep Board visual direction from PR #132.

Double-click `BlockBlastBattle-Day52.rbxl` when you want to test the newest
real BrickBlast game from `master`.

Important: Day49-Day51 were local feature-branch checkpoints for the One More
Chance prototype and card experiments. Day52 is newer and is the first Deep
Board build, but it does **not** include that unmerged One More Chance feature
branch yet.

## Folder Layout

| Location | Purpose |
| --- | --- |
| `src/` | Active Roblox source code. |
| `assets/ui/bubblegum-production/` | Current production Bubblegum UI art package. |
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
historical checkpoints through Day51 now live in `checkpoints/` and are kept
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
| `BlockBlastBattle-Day52.rbxl` | `master` at `15b080c` | First Deep Board master build. Current build to open. |

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
real `BlockBlastBattle-Day*.rbxl` checkpoint, which is currently Day52.

Next real numbered checkpoint: Day53.
