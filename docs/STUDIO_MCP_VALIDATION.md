# Roblox Studio MCP Validation

Status: **connected and in active use** (as of 2026-08-17, via Claude Code). The connection steps below worked as documented. `list_roblox_studios`, `get_console_output`, `start_stop_play`, and `screen_capture` have all been used successfully to read Output errors, cycle Play mode, and visually confirm UI changes without needing Yoel to do it by hand.

What this does **not** mean: the full device/viewport test matrix below is still mostly unexecuted. What's actually happened so far is targeted spot-checks (e.g. confirming a specific bug is fixed after a code change), not a systematic pass through every row in the matrix. Don't mark matrix rows `Pass` unless they were individually checked.

## Official MCP Connection Steps

Use the built-in Roblox Studio MCP server. Do not install a third-party Studio control plugin if the built-in server is available.

1. Update Roblox Studio to the latest version.
2. Open Roblox Studio.
3. Open `Assistant`.
4. Click `...` and choose `Manage MCP Servers`.
5. Turn on `Enable Studio as MCP server`.
6. In the same MCP Servers panel, expand `Quick connect`.
7. Select the Codex/Codex CLI option if it appears.
8. Confirm Studio shows the green connected-client indicator.
9. If Codex does not appear in Quick Connect, use the Windows command listed by Roblox:
   `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`
10. Restart Codex after adding or enabling the MCP connection.
11. In Codex, confirm Studio MCP tools are available by checking for `list_roblox_studios` or equivalent Roblox Studio tools.

## Opening The Local Place Safely

1. In Roblox Studio, use `File > Open from File...`.
2. Open the latest `BlockBlastBattle-Day*.rbxl` in this folder (the number keeps incrementing — check file timestamps, don't assume a specific one), or let Rojo serve straight into whatever place is already open.
3. Do not use `File > Publish to Roblox`.
4. Do not overwrite an existing live experience.
5. Keep testing local unless a deliberate release branch and Creator Dashboard plan exist.

## Connection Confirmation

Expected result after MCP is connected:

- Studio Assistant MCP panel shows a green connected-client indicator.
- The agent (Codex or Claude Code) exposes Roblox Studio MCP tools, including tools for listing Studio sessions, reading console output, starting/stopping play, capturing screens, and sending keyboard/mouse input.
- `list_roblox_studios` returns the currently-open local Studio session.

## Required Test Matrix

Mark each item `Pass`, `Fail`, or `Blocked` during the real Studio run. Capture screenshots wherever screen capture is supported.

| Test | Expected Result | Status |
| --- | --- | --- |
| Launch Play mode | Client and server start without output errors. | Unexecuted |
| Read client Output | No new HomePanel errors or warnings. | Unexecuted |
| Read server Output | No new server errors or warnings. | Unexecuted |
| Home initialization | Home appears in hub with Battle focused on gamepad. | Unexecuted |
| Battle button | Sends the existing battle or leave-queue action. | Unexecuted |
| Story button | Opens Story Missions and hides incompatible modals. | Unexecuted |
| Shop & Closet button | Opens Shop and hides Story/Cosmetic modal conflicts. | Unexecuted |
| Guide button | Reopens tutorial without resetting tutorial completion. | Unexecuted |
| Settings buttons | Motion, UI size, piece skin, board skin, and sound still update/save. | Unexecuted |
| Return to home from battle | Home returns when state becomes hub and was not manually closed. | Unexecuted |
| Repeated home show/hide | No duplicate callbacks, stuck tweens, or stale focus. | Unexecuted |
| Modal stacking | Story, Shop, Cosmetics, Guide, and Results do not layer incorrectly. | Unexecuted |
| Desktop 1920x1080 | No overlap, clipping, or unreadable text. | Unexecuted |
| Laptop 1366x768 | No overlap, clipping, or unreadable text. | Unexecuted |
| Tablet landscape | Home scales within safe area and controls remain reachable. | Unexecuted |
| Mobile landscape | Home scales and touch targets remain usable. | Unexecuted |
| Mobile portrait | Home scales without clipping important controls. | Unexecuted |
| Narrow aspect ratio | Side logo and home panel remain reachable. | Unexecuted |
| Minimum UI scale | Compact setting does not shrink text below usability. | Unexecuted |
| Maximum UI scale | Large setting does not overlap controls. | Unexecuted |
| Reduced motion | Home opens without tween motion and queued pulse is suppressed. | Unexecuted |
| Keyboard traversal | Activated controls can be triggered without mouse-only paths. | Unexecuted |
| Gamepad traversal | Focus moves between close, guide, battle, story, settings, cosmetics, shop. | Unexecuted |
| Hidden-element focus | Hidden home/logo elements do not retain focus. | Unexecuted |
| Two-player local server | Matchmaking lifecycle still works after extraction. | Unexecuted |
| Results to home | Finished run results close/requeue paths return to sensible focus. | Unexecuted |

## Screenshot Review Checklist

For each captured viewport, inspect:

- overlap
- clipping
- unreadable text
- bad spacing
- unreachable controls
- excessive empty space
- board obstruction
- incorrect modal layering
- unsafe device inset placement
- broken focus order

## Notes

- HomePanel owns home UI instances, home UI connections, home show tween, queued pulse tween, and home focus paths.
- `BlockBlastClient.client.luau` still owns networking, settings state, tutorial state, shop/story/cosmetic modal orchestration, and gameplay state.
- Studio validation is the next external step after repository validation.
