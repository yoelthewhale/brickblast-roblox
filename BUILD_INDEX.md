# BrickBlast Build Index

## CURRENT GAME TO OPEN

`BlockBlastBattle-Day50.rbxl`

- Source branch: `feature/one-more-chance-free-prototype`
- Source commit: `1eba99f`
- Built: `2026-08-22 15:38:48 -04:00`
- Location: repository root
- Purpose: current local checkpoint with the simplified solo test hub, Claude's merged left-nav HUD fix, the free One More Chance Solo prototype, the reviewed Bubblegum continue panel, and the Solo end-flow fix that keeps results anchored to the puzzle workspace.

Double-click `BlockBlastBattle-Day50.rbxl` when you want to test the newest
real BrickBlast game.

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

Some recent historical files remain in the root because Windows denied access
while a background `RobloxStudioBeta` process was present:

- `BlockBlastBattle-Day43.rbxl`
- `BlockBlastBattle-Day44.rbxl`
- `BlockBlastBattle-Day44-1.rbxl`
- `BlockBlastBattle-Day45.rbxl`

Those files are obsolete for day-to-day testing and are hidden in VS Code
Explorer. Keep them unless we deliberately close the locking process and move
them later.

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

`BrickBlast-Day50-LatestTest.rbxl` remains in the root only because Windows
denied access while cleaning up. Day50 was an accidental local alias, not a real
checkpoint. It is hidden in VS Code Explorer and should be ignored.

## Checkpoint Rule

Do not invent Day numbers. The next Day number comes from the highest existing
real `BlockBlastBattle-Day*.rbxl` checkpoint, which is currently Day50.

Next real numbered checkpoint: Day51.
