# Copilot instructions for BrickBlast

BrickBlast is a Roblox block-puzzle game written in Luau, synced into Roblox Studio with Rojo.

## What this game currently is

- **Solo 8x8 block puzzle only.** Place pieces from a 3-piece tray, clear rows/columns, chase combos and stages.
- **Battle, Story, and Custom Lab are disabled legacy systems.** Their code still exists behind flags in `src/shared/game/ExperienceConfig.luau`. Do not revive, extend, or "fix" them unless explicitly asked. Suggesting Battle/Story features is almost always wrong.

## Hard rules

- **8x8 board invariant.** The board is exactly `Config.BoardSize` squared (currently 64 cells). `BoardGridContainer` must contain exactly 64 direct cell buttons and no decorative children. Board math uses `AbsolutePosition`/`AbsoluteSize`.
- **Server authority.** Score, currency, XP, rewards, cosmetic ownership, and saved data are decided on the server only. Never accept a client-supplied value for these without server-side validation against real state.
- **Both major monoliths are register-sensitive.** Each is a single top-level Luau chunk close to the compiler's 200-local-register limit, and each has already blown past it once, failing to compile with no symptom beyond one "Out of local registers" line in Studio's Output:
  - `src/client/ui/BlockBlastClient.client.luau` — silently broke the entire HUD. Attach values to the existing `day43Ui` table.
  - `src/server/services/GameServer.server.luau` — silently broke the entire server on 2026-08-19 (#96 / PR #97): no hub, no remotes, players on the bare bootstrap floor. Attach values to an existing table, or move the concern into a ModuleScript.
  In neither file may you add a new top-level `local` declaration, including a local function. `lune run scripts/check-local-registers.luau` enforces a budget per file in CI; the fix for a failure is to remove a local, never to raise the budget.
- **`src/server/services/GameServer.server.luau` is also a large, sensitive monolith** (~3,400 lines) containing profile saving, purchases, and rewards. Make small, targeted edits. Do not restructure it opportunistically.

## Sensitive areas — extra care required

Changes here can lose player data, create exploits, or break purchases:

- DataStore reads/writes, profile load/save, schema/versioning
- Currency, XP, rewards, achievements granting
- `ProcessReceipt`, gamepasses, developer products
- RemoteEvent/RemoteFunction handlers, validation, rate limiting
- The developer-tools UserId allowlist

In these areas: explain the risk and the reasoning before proposing code, and prefer the smallest change that solves the stated problem.

## Code layout

| Path | Purpose |
| --- | --- |
| `src/client/ui/` | Client-only UI. Runs per player. |
| `src/server/services/` | Server-authoritative gameplay, saves, economy. |
| `src/server/world/` | Procedurally generated hub world. |
| `src/shared/game/` | Rules shared by client and server, plus `*Tests.luau`. |

Pure game logic belongs in `src/shared/game/` where it can be unit tested.

## Style and conventions

- Luau, formatted by StyLua (`stylua.toml`: tabs, 100 columns, Unix line endings) and linted by Selene.
- Match the surrounding file's existing style, naming, and comment density.
- Comments should explain *why*, not restate the code.

## Validation commands

Run from the repository root:

```bash
stylua src
selene src
lune run scripts/run-tests.luau
rojo build default.project.json --output BrickBlast-check.rbxl
git diff --check
```

Tests only cover `src/shared/game/`. Anything under `src/client/` or `src/server/` depends on real Roblox services and **must be verified in Roblox Studio** — if behavior cannot be confirmed by reading the source, say so and recommend a Studio test rather than asserting it works.

## Workflow

- Work is tracked in GitHub Issues; follow the issue's stated acceptance criteria.
- Branch from `master` (`fix/`, `feat/`, `docs/`, `chore/`, `test/` + issue number), never commit directly to `master`.
- One issue per branch/PR. Keep changes scoped — do not modify unrelated systems in the same change.
- Reference the issue in the PR description (`Closes #NN`). CI must pass before merge.
- Full details in [`CONTRIBUTING.md`](../CONTRIBUTING.md).

## Mobile

Mobile is **not** currently supported and is a known gap: piece dragging is mouse-only, and the Solo gameplay layout overflows on phone-width screens. When touching UI, do not assume mouse-only input is acceptable long-term, but also do not silently expand a task into a mobile port.
