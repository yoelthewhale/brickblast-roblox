# Multiplayer Stress Test Plan

Use this checklist in Roblox Studio local server tests before treating matchmaking as stable.

## Setup

- Open `BlockBlastBattle-Day3.rbxl` in Roblox Studio.
- Start a local server from the Test tab.
- Use the latest Rojo sync if editing scripts live.
- Keep the Output window open and clear before each scenario.

## Diagnostics To Watch

- Studio diagnostics overlay: current player, mode, arena, match, queue, active session summaries, and profile load/save failure counters.
- Studio diagnostics overlay: profile load/save failure counters should stay at `0/0`.
- Hub panel: `Arenas`, `Matches`, and queued player count.
- Battle window: `Arena -- | Match --` line.
- Battle dock: minimized players should still show arena and score.
- Scoreboard/leaderboard: each match should only show players in that same match.
- Server Output: no red errors, runaway warnings, or repeated DataStore failures.

## Scenario A: Solo Queue Fallback

1. Start a local server with 1 player.
2. Join Battle Queue.
3. Wait for the solo-test countdown.

Pass criteria:

- Hub queue count shows `1/2 queued`.
- Solo countdown reaches zero.
- Player enters a battle board in one arena.
- Battle UI shows an arena number and match number.
- Returning to hub frees the arena count.

## Scenario B: Two-Player Battle

1. Start a local server with 2 players.
2. Join Battle Queue on both clients.
3. Place blocks on both boards.
4. Force one player out of moves or wait for timer expiry.

Pass criteria:

- Both players share the same match number.
- Both players show the same arena number.
- Leaderboard contains only those two players.
- Winner result appears once.
- Rewards are granted once per player.
- Both players return to the hub after the result delay.

## Scenario C: Two Simultaneous Matches

1. Start a local server with 4 players.
2. Join Battle Queue on all clients.

Pass criteria:

- Two separate matches start.
- Each pair has a distinct match number.
- Each pair has a distinct arena number.
- Each leaderboard only lists the two players in that match.
- Hub shows `Matches: 2`.

## Scenario D: Arena Capacity

1. Start a local server with 7 players.
2. Join Battle Queue with six players first.
3. Confirm all three arenas become active.
4. Join Battle Queue with the seventh player.

Pass criteria:

- Hub shows `Arenas: 0/3 open`.
- Seventh player sees full-arena feedback.
- Seventh player can join once one match ends and an arena frees.
- No player is teleported into an occupied arena slot.

## Scenario E: Leave Queue And Leave Battle

1. Queue one player, then press `Queued - Leave Queue`.
2. Queue two players and start a match.
3. Use `Return Hub` from one player.

Pass criteria:

- Leaving queue decrements queue count.
- Leaving battle removes only that player from the match.
- Remaining player gets proper finish behavior.
- Arena frees when the session empties.

## Scenario F: Client Settings Persistence

1. Change theme, UI size, motion, sound, and piece style.
2. Rejoin the local server.

Pass criteria:

- Settings reload after join.
- Piece style affects newly generated hands.
- Sound Off prevents client cues.
- Reduced Motion disables pulsing/shaking.
- Studio diagnostics profile failure counters remain at `0/0` after rejoin.

## Failure Notes

Record each failure with:

- Scenario letter.
- Player count.
- Match number and arena number from each affected client.
- Studio diagnostics overlay text from each affected client.
- Exact Output error text.
- Repro steps.
