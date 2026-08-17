# BrickBlast — Start Here

New to this repo? Read this first, then [`README.md`](README.md) for current status and [`AGENTS.md`](AGENTS.md) if you're using an AI coding agent (Claude Code, Codex) on this project.

Project folder:

`C:\Users\Bear4\Documents\Codex\2026-07-28\build\outputs\block-blast-battle`

## Open In VS Code

Open this folder, not one of the parent `Codex` folders:

`C:\Users\Bear4\Documents\Codex\2026-07-28\build\outputs\block-blast-battle`

## Where Things Live

- `src/client/ui/` — player HUD, menus, shop, achievements, codes, result screens, notifications. Client-only, runs per-player.
- `src/server/services/` — server-authoritative gameplay: queues, matches, leaderstats, saves, achievements, codes, remotes.
- `src/server/world/` — generated hub/world construction (`HubBuilder.luau`).
- `src/shared/game/` — rules both client and server use: board logic (`Grid.luau`), pieces (`Blocks.luau`), config, achievements, and every `*Tests.luau` module.
- `docs/` — current rules/setup docs, plus `docs/archive/` for historical snapshots that are no longer accurate.
- `scripts/` — helper scripts, including `run-tests.luau` (the headless test runner) and `open-latest-local-build.ps1`.
- `tools/` — pinned local CLI binaries (Rojo, StyLua, Selene, Wally, Lune) used by VS Code tasks so you don't need them globally installed.

## Tooling Files

- `default.project.json` — Rojo map from files to Roblox Studio services.
- `rokit.toml` — pinned command-line tool versions (`rokit install` fetches them).
- `wally.toml` — Roblox package dependencies.
- `selene.toml` / `stylua.toml` — Luau lint/format config.
- `BlockBlastBattle.code-workspace` — clean VS Code workspace entry point.

## Open The Latest Local Build

Run this from PowerShell:

```powershell
.\scripts\open-latest-local-build.ps1
```

Before pressing Play, check the top-right Roblox Studio account. It should say:

`CAPTINNINJATACO`

If it opens as a different account, sign out inside Roblox Studio and sign back in as `CAPTINNINJATACO`. Scripts here cannot safely change Roblox login credentials — that has to happen by hand in Studio.

## Build And Validate

Useful VS Code tasks (see `.vscode/tasks.json` for the full list):

- `Rojo: Serve` — start live sync so Studio picks up file changes immediately.
- `Rojo: Build Place` — build a fresh `.rbxl`.
- `Luau: Format With StyLua` / `Luau: Lint With Selene`
- `Studio: Open Latest Local Build`

Or from PowerShell directly:

```powershell
.\tools\stylua.exe src
.\tools\selene.exe src
.\tools\lune.exe run scripts/run-tests.luau
```

Latest generated builds stay in this folder as `BlockBlastBattle-Day*.rbxl` — never overwrite an earlier one, always build to a new filename.

## Tracking Work

Task tracking is GitHub Issues + the **BrickBlast Development** project board, not a doc in this repo. See [`docs/PROJECT_TRACKER.md`](docs/PROJECT_TRACKER.md) for links and labels.
