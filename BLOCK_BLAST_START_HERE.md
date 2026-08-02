# Block Blast Battle - Start Here

Project folder:

`C:\Users\Bear4\Documents\Codex\2026-07-28\build\outputs\block-blast-battle`

## Open In VS Code

Open this folder, not one of the parent `Codex` folders:

`C:\Users\Bear4\Documents\Codex\2026-07-28\build\outputs\block-blast-battle`

Important places:

- `src/client/ui` - player HUD, menus, shop, result screens, notifications.
- `src/server/services` - server-authoritative gameplay, queues, rewards, shop receipts.
- `src/server/world` - generated hub, islands, portals, arena map, lighting.
- `src/shared/game` - rules shared by client and server, including blocks/grid/config.
- `docs` - project tracker, Studio validation notes, Creator Dashboard steps.
- `tools` - pinned Rojo, StyLua, Selene, Wally tools.

## Open The Latest Local Build

Run this from PowerShell:

```powershell
.\scripts\open-latest-local-build.ps1
```

Before pressing Play, check the top-right Roblox Studio account. It should say:

`CAPTINNINJATACO`

If it opens as your cousin's account, sign out inside Roblox Studio and sign back in as
`CAPTINNINJATACO`. The project scripts cannot safely change Roblox login credentials.

## Build And Validate

Useful VS Code tasks:

- `Rojo: Serve`
- `Rojo: Build Day17`
- `Luau: Format With StyLua`
- `Luau: Lint With Selene`
- `Studio: Open Latest Local Build`

Latest generated builds stay in this folder as `BlockBlastBattle-Day*.rbxl`.
