# Project Map

Use this as the first place to look when you want to change the game.

## Roblox-Synced Source

- `src/client/ui/` - client-only UI scripts that run for each player.
- `src/server/services/` - server systems: queues, matches, leaderstats, saves, remotes.
- `src/server/world/` - generated world/hub construction.
- `src/shared/game/` - shared Block Blast rules, board logic, pieces, and config.
- `docs/` - project planning, Tuesday.com import files, roadmap, bugs, and playtest notes.

## Tooling

- `default.project.json` - Rojo map from files to Roblox Studio services.
- `rokit.toml` - pinned command-line tools.
- `wally.toml` - Roblox package dependencies.
- `selene.toml` - Luau lint config.
- `stylua.toml` - Luau formatter config.
- `tools/` - local CLI binaries used by VS Code tasks.

## Current Entry Points

- Server: `src/server/services/GameServer.server.luau`
- Client: `src/client/ui/BlockBlastClient.client.luau`
- Shared puzzle logic: `src/shared/game/Grid.luau`
- Piece definitions: `src/shared/game/Blocks.luau`
- Hub generation: `src/server/world/HubBuilder.luau`
- Tracker: `docs/PROJECT_TRACKER.md`
- Multiplayer stress test plan: `docs/MULTIPLAYER_STRESS_TEST.md`
- Tuesday import CSV: `docs/TUESDAY_IMPORT.csv`
