# Block Blast Battle Project Tracker

This tracker mirrors the Tuesday.com board named `Game development`.

## Tuesday Columns

- `Task`
- `Priority`
- `Status`
- `Owner`
- `Due Date`

## Status Labels

- `Backlog` - planned, not started yet.
- `Ready` - clear enough to start next.
- `In Progress` - actively being built or debugged.
- `Playtest` - needs Roblox Studio testing.
- `Done` - built and verified.
- `Blocked` - waiting on a decision, account action, or tool access.

## Current Roadmap

| Task | Priority | Status | Owner | Due Date |
| --- | --- | --- | --- | --- |
| Verify Day 2 place opens and Rojo connects | High | Playtest | Bear / Codex | 2026-07-29 |
| Test adjustable battle UI in Roblox Studio | High | Playtest | Bear / Codex | 2026-07-29 |
| Test hover placement preview and blocked-placement feedback | High | Playtest | Bear / Codex | 2026-07-29 |
| Fix any Day 2 Studio errors from Output window | High | Ready | Codex | 2026-07-30 |
| Add queue countdown and match-start banner | High | In Progress | Codex | 2026-07-30 |
| Add story-mode placeholder flow with a starter mission | Medium | Playtest | Codex | 2026-07-31 |
| Add battle arenas per match instead of one shared arena | High | In Progress | Codex | 2026-08-01 |
| Add player customization save data for UI theme and layout | Medium | Backlog | Codex | 2026-08-01 |
| Add piece skin customization menu | Medium | Backlog | Codex | 2026-08-02 |
| Add round timer and sudden-death pressure | High | In Progress | Codex | 2026-08-02 |
| Add rewards after battles: coins, XP, and wins | High | Backlog | Codex | 2026-08-03 |
| Add permanent leaderboard stats for wins and best score | High | Backlog | Codex | 2026-08-03 |
| Improve hub visuals and signposting | Medium | In Progress | Codex | 2026-08-04 |
| Add sound effects for placing, clearing, queueing, and winning | Medium | Backlog | Codex | 2026-08-04 |
| Add mobile-friendly controls and scale testing | High | Backlog | Codex | 2026-08-05 |

## Bug Tracker

| Bug | Priority | Status | Owner | Due Date |
| --- | --- | --- | --- | --- |
| Original `.rbxl` file may stay locked while Studio has it open | Medium | Known | Bear / Codex | 2026-07-29 |
| Need confirm Rojo plugin connects to Day 2 place | High | Playtest | Bear / Codex | 2026-07-29 |
| Need test two-player battle end condition in Studio multiplayer test | High | Ready | Bear / Codex | 2026-07-30 |

## Playtest Checklist

- Start Rojo server from VS Code or `start-rojo.ps1`.
- Open `BlockBlastBattle-Day3.rbxl` in Roblox Studio.
- Connect the Rojo plugin to `localhost:34872`.
- Press Play and confirm the hub appears.
- Close the hub UI with `X`, then reopen it with the `BB` side logo.
- Walk from the hub bridge into the first battle arena and confirm the two player decks, glow pillars, and scoreboard render.
- Join battle queue and wait for solo test battle.
- Confirm queued players see the solo-test countdown.
- Start Story Mode and confirm it opens a solo `Story Training` board.
- Confirm battle start and result banners animate in.
- Confirm the battle window shows a round timer.
- Confirm the UI window can drag, resize, hide, reopen, and reset.
- Confirm pieces auto-select and board hover previews show placement.
- Try an invalid placement and confirm the UI shakes and says `That spot is blocked`.
- Place pieces and confirm blocks pop in; clear a row or column and confirm cleared cells flash.
- Fill the board until out of moves and confirm it returns to hub.
- Run a two-player local server test and confirm a winner message appears.

## Build Notes

- 2026-07-29 Day 3: Added the first battle arena map, side-specific arena spawns, client effect banners, queue pulse, placement pops, clear flashes, invalid-placement shake, closable hub UI, side-logo hub access, round timer, basic wins stat, progression rewards, accessibility scaling, anti-spam remote checks, and starter story training. Built `BlockBlastBattle-Day3.rbxl`.
