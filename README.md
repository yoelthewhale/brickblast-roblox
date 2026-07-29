# Block Blast Battle

A Rojo-powered Roblox project for a battle version of Block Blast.

See `PROJECT_MAP.md` for where each part of the game lives.

Project management lives in `docs/PROJECT_TRACKER.md`, with a Tuesday.com-ready CSV at
`docs/TUESDAY_IMPORT.csv`.

Multiplayer validation steps live in `docs/MULTIPLAYER_STRESS_TEST.md`.

## Setup

1. Open this folder in VS Code.
2. Install the recommended extensions when VS Code prompts you.
3. Start Rojo from the VS Code Rojo menu or run:

   ```powershell
   rojo serve default.project.json
   ```

4. In Roblox Studio, install/open the Rojo plugin and connect to the local server.
5. Press Play in Studio.

## Tooling From The Setup Video

This project includes the Roblox external tooling stack from the video:

- Rokit for pinning CLI tools.
- Rojo for VS Code to Roblox Studio sync.
- Wally for Roblox packages.
- wally-package-types for package type support.
- StyLua for Luau formatting.
- Selene for Luau linting.

The tools are pinned in `rokit.toml` and copied into `tools/` so the VS Code tasks can run without relying on your global PATH.

Useful VS Code tasks:

- `Tools: Install With Rokit`
- `Rojo: Serve`
- `Rojo: Build Place`
- `Rojo: Generate Sourcemap`
- `Wally: Install Packages`
- `Wally: Generate Package Types`
- `Luau: Format With StyLua`
- `Luau: Lint With Selene`

## Game Loop

- Each player gets an 8x8 board and three block pieces.
- Place pieces to fill rows or columns.
- Clearing lines scores points and sends pressure to opponents.
- Incoming pressure fills cells from the bottom unless the player keeps clearing lines.

This is intentionally a small, readable prototype so you can start changing rules and adding visuals quickly.
