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
| Add story-mode mission flow with objectives and rewards | Medium | Playtest | Codex | 2026-07-31 |
| Add hub story chapter preview and mission framing | Medium | Playtest | Codex | 2026-07-31 |
| Add story chapter intro and result copy | Medium | Playtest | Codex | 2026-07-31 |
| Add story mission-select panel and replay-safe chapter starts | Medium | Playtest | Codex | 2026-07-31 |
| Add battle arenas per match instead of one shared arena | High | Playtest | Codex | 2026-08-01 |
| Add player customization save data for UI theme and layout | Medium | Playtest | Codex | 2026-08-01 |
| Add progression-gated piece and board skin customization | Medium | Playtest | Codex | 2026-08-02 |
| Add hub cosmetic preview swatches | Medium | Playtest | Codex | 2026-08-02 |
| Add cosmetic closet panel | Medium | Playtest | Codex | 2026-08-02 |
| Add round timer and sudden-death pressure | High | Playtest | Codex | 2026-08-02 |
| Add combo streak scoring and result stats | High | Playtest | Codex | 2026-08-02 |
| Add rewards after battles: coins, XP, wins, and Story Stars | High | Playtest | Codex | 2026-08-03 |
| Add permanent leaderboard stats for wins, best score, and Story Stars | High | Playtest | Codex | 2026-08-03 |
| Add first-win daily bonus loop | High | Playtest | Codex | 2026-08-03 |
| Add post-run results panel | Medium | Playtest | Codex | 2026-08-03 |
| Add next-unlock hints to post-run results | Medium | Playtest | Codex | 2026-08-03 |
| Improve hub visuals and signposting | Medium | In Progress | Codex | 2026-08-04 |
| Add sound effects for placing, clearing, queueing, and winning | Medium | Playtest | Codex | 2026-08-04 |
| Extract client sound controller module | Medium | Playtest | Codex | 2026-08-04 |
| Add mobile-friendly controls and scale testing | High | Playtest | Codex | 2026-08-05 |
| Add replayable hub guide button | Medium | Playtest | Codex | 2026-08-05 |
| Harden profile save reliability and diagnostics | High | Playtest | Codex | 2026-08-05 |
| Harden numeric settings sanitization on server and client | High | Playtest | Codex | 2026-08-05 |
| Add server playtest analytics hooks | Medium | Playtest | Codex | 2026-08-05 |
| Prevent early-leave reward farming | High | Playtest | Codex | 2026-08-06 |
| Add suspicious placement remote diagnostics | High | Playtest | Codex | 2026-08-06 |
| Harden play-again queue lifecycle | High | Playtest | Codex | 2026-08-06 |

## Bug Tracker

| Bug | Priority | Status | Owner | Due Date |
| --- | --- | --- | --- | --- |
| Original `.rbxl` file may stay locked while Studio has it open | Medium | Known | Bear / Codex | 2026-07-29 |
| Need confirm Rojo plugin connects to Day 2 place | High | Playtest | Bear / Codex | 2026-07-29 |
| Need test two-player battle end condition in Studio multiplayer test | High | Ready | Bear / Codex | 2026-07-30 |

## Playtest Checklist

- Start Rojo server from VS Code or `start-rojo.ps1`.
- Open `BlockBlastBattle-Day4.rbxl` in Roblox Studio.
- Connect the Rojo plugin to `localhost:34872`.
- Confirm the loading splash appears briefly and fades after game state arrives.
- Press Play and confirm the hub appears.
- Confirm first-time onboarding appears, `Got It` dismisses it, and `Try Story` starts Story Training.
- Press the hub `Guide` button after dismissing onboarding and confirm the tutorial can be replayed without losing saved completion.
- Close the hub UI with `X`, then reopen it with the `BB` side logo.
- Change theme, board skin, motion, UI size, and piece style, rejoin the session, and confirm those settings reload.
- Confirm Studio diagnostics profile failure counters stay at `0/0` after settings changes, rewards, and rejoin.
- Confirm Studio diagnostics analytics counters update for queueing, story starts, battle starts, placements, clears, invalid placements, and forfeits.
- Confirm Studio diagnostics rejected/throttled placement counters move for malformed, stale-session, or rapid repeated placement remotes without changing score.
- Leave an active battle/story run early and confirm no rewards are granted.
- Return to the hub after a win, story run, out-of-moves run, and forfeit; confirm the hub status keeps that player's own result summary.
- Confirm the post-run results panel shows outcome, score, lines, coins, XP, Story Stars when earned, best-score progress, next cosmetic unlock, close, and quick battle queue.
- Claim the first-win daily bonus once through a battle victory or next story chapter completion and confirm the hub/result text does not grant it twice on replay.
- Use `Play Again` from the battle window and `Queue Battle` from results; confirm each uses one server replay flow, never grants duplicate rewards, and cannot requeue from an active unfinished run.
- Cycle Sound setting and confirm UI/gameplay cues respect the selected volume or Off state.
- Start a new run after changing piece style and confirm new pieces use the selected style; change board skin and confirm empty board cells update without recoloring placed pieces.
- Confirm the hub piece and board skin buttons show swatches that update when cycling unlocked cosmetics.
- Open the cosmetic closet from the hub, equip unlocked piece and board skins directly, confirm locked cards show requirements, and confirm selections persist after rejoin.
- Confirm locked cosmetics show the next unlock requirement and cannot be selected before the required Level, Coins, or Story Stars.
- Walk from the hub bridge into the first battle arena and confirm the two player decks, glow pillars, and scoreboard render.
- Confirm three battle arenas render with separate scoreboard labels and return pads.
- Join battle queue and wait for solo test battle.
- Confirm the hub shows open arenas, active matches, and queue size.
- Confirm queued players see the solo-test countdown.
- Fill all arenas in a local server test and confirm the hub shows full-arena feedback.
- Run a local multiplayer test with 4+ players and confirm separate two-player sessions get separate arena spawns and leaderboards.
- Follow `docs/MULTIPLAYER_STRESS_TEST.md` and record failures with scenario letter, player count, arena, and match number.
- Start Story Mode and confirm it opens a solo `Story Training` board.
- Confirm the hub Story button shows the next mission title and objective before starting.
- Open the Story Missions panel, start the next chapter, replay a completed chapter, and confirm locked upcoming chapters cannot start.
- Complete a replayed chapter and confirm it does not award an extra Story Star.
- Confirm Story Training start banner shows mission intro copy, in-run objective includes chapter number, and results show success/failure story copy.
- In Story Training, confirm the mission goal text updates while scoring and that completion grants Story Stars.
- Confirm battle start and result banners animate in.
- Confirm the battle window shows a round timer.
- Confirm battle matches enter red sudden-death timer state in the final 30 seconds and pressure rows rise every 10 seconds.
- Confirm the UI window can drag, resize, hide, reopen, and reset.
- Resize the battle window below desktop width or use device emulation and confirm the board stacks above touch-friendly piece controls.
- Confirm pieces auto-select and board hover previews show placement.
- Try an invalid placement and confirm the UI shakes and says `That spot is blocked`.
- Place pieces and confirm blocks pop in; clear a row or column and confirm cleared cells flash.
- Clear lines on consecutive placements and confirm combo banners, bonus score, and best combo result stats appear.
- Fill the board until out of moves and confirm it returns to hub.
- Run a two-player local server test and confirm a winner message appears.

## Build Notes

- 2026-08-01 Day 4: Added finite-number settings hardening and built `BlockBlastBattle-Day4.rbxl` because Day 3 was locked by Studio.
