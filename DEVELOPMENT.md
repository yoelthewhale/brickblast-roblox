# Block Blast Battle Development Log

This file tracks production-readiness work, priorities, known issues, and technical debt.

## Day37.3 Reference-Quality PC UI Polish - 2026-08-13

### Completed

- Continued from commit `b32e28d` after Yoel approved the corrected 8x8 board hierarchy.
- Kept `BoardGridContainer` locked with one `UIPadding`, one `UIGridLayout`, and exactly 64 direct cell buttons.
- Reduced the root workspace shell opacity so the toybox world remains visible behind the PC puzzle UI.
- Rebalanced the header into a target-like control row with real coin chip, theme, Settings, Help, Reset, and Close controls.
- Added functional PC Settings and Help buttons using existing settings/info and tutorial systems.
- Improved code-native glossy block depth with contained shadows, bevel/stroke layers, highlights, and a subtle embossed symbol.
- Enlarged tray previews and reduced technical label dominance while preserving piece selection and drag blockers.
- Added cached real Roblox avatar thumbnail loading for Server Top rows using `Players:GetUserThumbnailAsync`; no fake rows are generated.
- Restyled the result/Play Again popup into the same arcade panel language and moved it to the lower-right area.
- Built `BlockBlastBattle-Day37-3.rbxl`.

### Current State

- Source/build validation passes.
- Runtime Studio screenshots were not captured in this session, so Yoel still needs to approve the visual match in Studio.
- The board hierarchy remains guarded by the existing one-time validation warning.

### Required Manual Checks

1. Open `BlockBlastBattle-Day37-3.rbxl` and start Solo Puzzle.
2. Confirm the board still has exactly 8 rows and 8 columns and no decorative grid sibling appears.
3. Confirm Settings, Help, Reset, Close, Return Hub, Play Again, and piece selection remain functional.
4. Confirm Server Top shows real player thumbnails or safe placeholders without fake entries.
5. Trigger game over and confirm the lower-right result panel fits and Play Again starts a clean run.
6. Drag and resize at minimum/default/maximum scale and place pieces after each change.

## Day37.2.1 PC UI Layout Bug Fix - 2026-08-12

### Completed

- Continued from commit `a75efb9` without amending Day37.2.
- Inspected Yoel's runtime screenshot and fixed only the visible layout/contrast bugs reported.
- Traced the extra visible board cells to layout overflow, not logical board generation:
  - the board still creates cells only through `for y = 1, Config.BoardSize` and `for x = 1, Config.BoardSize`
  - Day37.2 board math used a board frame that did not clip descendants
  - glossy cell children and shadows could visibly extend below the board surface
  - the piece tray began too close to the board, making the overflow read as extra cells behind the tray
- Fixed board sizing math:
  - cell size is `45`
  - padding between cells is `4`
  - board padding is `18`
  - visible board size is `(8 * 45) + (7 * 4) + (2 * 18) = 424`
- Added `boardFrame.ClipsDescendants = true` as a safety boundary after fixing the frame sizing math.
- Moved the piece tray lower to create clean spacing below the board at default, minimum, and maximum workspace scale.
- Fixed Combo, Coins, and Rank card contrast by forcing readable final text colors and stroke transparency after arcade helper styling and during layout refresh.
- Built `BlockBlastBattle-Day37-2-1.rbxl`.

### Current State

- Day37.2.1 should show exactly 8 visible board rows and 8 visible board columns, with no cells leaking below the board.
- The logical board remains exactly 8x8 and gameplay code was not changed.
- Runtime Studio verification is still required because Codex could not capture a Play-mode screenshot here.

### Required Manual Checks

1. Open `BlockBlastBattle-Day37-2-1.rbxl`.
2. Start Solo Puzzle and confirm exactly 64 visible cells.
3. Confirm no board cell or glossy shadow appears beneath the board or behind the piece tray.
4. Resize to `0.78x`, default, and `1.22x` and confirm board/tray spacing stays clean.
5. Confirm Combo, Coins, and Rank text remain readable.
6. Move and resize the workspace, then place pieces.
7. Return Hub and reopen Solo Puzzle.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with 0 errors and 0 warnings; Selene used its cached Roblox standard library after failing to generate a fresh API dump.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day37-2-1.rbxl` passed.
- `git diff --check` passed with the repo's existing LF-to-CRLF working-copy warning.

## Day37.2 PC Arcade UI Visual Rebuild - 2026-08-12

### Completed

- Continued from commit `52e9c39` without amending Day37 or Day37.1.
- Kept locked Day37.1 interaction behavior: safe-area dragging, drag blockers, proportional resize, Reset Layout, screen clamping, Return Hub, Play Again, and board input wiring remain intact.
- Added `src/client/ui/ArcadeUI.luau` for reusable Roblox-native arcade styling:
  - molded navy panels
  - arcade text styling
  - arcade buttons
  - stat cards
  - glossy blocks
  - board cells
  - piece slots
  - leaderboard rows
- Restyled `PCPuzzleWorkspace` into a darker rounded arcade shell with layered blue rim, top highlight, slim draggable title, centered grip dots, and a close button that uses the existing server leave flow.
- Rebuilt the left stats stack with arcade-styled score/best, combo, coins, and honest rank card.
- Restyled the 8x8 board with a thick navy bezel, cyan-blue rim, quieter empty cells, and glossy child blocks for filled/preview/invalid cells.
- Restyled the three-piece tray into one wide arcade panel with three piece slots and code-rendered glossy previews.
- Replaced the old single text Server Top label with code-native rows that render real leaderboard entries, highlight the local player, and show an honest empty state.
- Preserved real data bindings for score, best score, combo, coins, derived current-server rank, board state, pieces, selected piece, and Server Top entries.
- Built `BlockBlastBattle-Day37-2.rbxl`.

### Current State

- Day37.2 is ready for visual inspection in Roblox Studio.
- No runtime Studio screenshot was captured by Codex in this environment.
- The UI is still Roblox-native, not a pasted flat image, so it should remain interactive after dragging and resizing.

### Known Issues

- Avatar thumbnails in Server Top are represented by code-native avatar placeholders; no external image assets or thumbnail APIs were added in Day37.2.
- The UI is visually closer to the references but still lacks true bitmap-level beveled art polish.
- Manual Studio proof is required for final appearance, clipping checks, resize extremes, and piece placement after resizing.

### Required Manual Checks

1. Open `BlockBlastBattle-Day37-2.rbxl`.
2. Start Solo Puzzle and capture the default PC workspace.
3. Compare the outer frame, left stat cards, board, piece tray, and Server Top against the attached arcade references.
4. Drag from safe areas and confirm interactive controls still block dragging.
5. Resize to minimum and maximum and confirm no clipping or overlap.
6. Place all three pieces after moving and resizing.
7. Confirm glossy preview and invalid placement states remain aligned with board cells.
8. Confirm score, best, combo, coins, and Server Top rows update from real gameplay.
9. Use Reset Layout.
10. Use Close/Return Hub, reopen Solo Puzzle, and confirm no duplicate HUD or input handlers.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with 0 errors and 0 warnings; Selene used its cached Roblox standard library after failing to generate a fresh API dump.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day37-2.rbxl` passed.
- `git diff --check` passed with the repo's existing LF-to-CRLF working-copy warning.

## Day37.1 PC Window Dragging and Resizing - 2026-08-12

### Completed

- Continued from commit `8b0f80b` without amending Day37.
- Kept the hub map frozen; no world, map, lighting, scenery, gameplay rules, scoring, DataStore, receipt, cosmetic, or mobile work was changed.
- Expanded PC Solo Puzzle workspace dragging beyond the title bar:
  - `PCPuzzleWorkspace` background can start dragging.
  - Score, combo, coin, and piece-tray panel backgrounds can start dragging.
  - Board cells, piece buttons, action buttons, leaderboard panel, reset button, theme button, and resize handle are marked as interactive blockers.
- Added a bottom-right `WorkspaceResizeHandle`.
- Implemented proportional resize by adjusting a workspace-level scale value instead of stretching individual panels.
- Added `Reset Layout`, which restores the default centered position and default workspace scale without touching score, board state, or the active run.
- Preserved the existing board-cell buttons and Roblox UI absolute positioning, so hover and placement continue to use the actual cell controls after moving or resizing.
- Built `BlockBlastBattle-Day37-1.rbxl`.

### Current State

- Day37.1 is ready for PC drag-and-resize inspection in Studio.
- Runtime Studio testing and screenshots were not captured by Codex in this environment.

### Known Issues

- Manual Studio proof is still required for drag-from-empty-space behavior, resize edge cases, and board placement after resizing.
- Resizing is intentionally PC mouse only; touch, gamepad, saved size, minimize, maximize, and mobile-specific behavior remain out of scope.

### Required Manual Checks

1. Open `BlockBlastBattle-Day37-1.rbxl`.
2. Start Solo Puzzle and drag from the title bar.
3. Drag from empty workspace background, score/combo/coins panel background, and empty piece-tray background.
4. Confirm board cells, piece buttons, Return Hub, Play Again, Theme, Reset Layout, leaderboard, and resize handle do not drag the workspace.
5. Resize smaller and larger from the bottom-right handle.
6. Drag and resize against all four screen edges and confirm the workspace remains recoverable.
7. After moving and resizing, place all three pieces and confirm hover/preview/placement remain aligned.
8. Use Reset Layout and confirm only position/scale reset.
9. Return Hub, reopen Solo Puzzle, and confirm no duplicate input behavior.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with 0 errors and 0 warnings; Selene used its cached Roblox standard library after failing to generate a fresh API dump.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day37-1.rbxl` passed.
- `git diff --check` passed with the repo's existing LF-to-CRLF working-copy warning.

## Day37 PC Puzzle Workspace Foundation - 2026-08-12

### Completed

- Froze the hub map completely for this checkpoint; `src/server/world/HubBuilder.luau`, world geometry, lighting, attractions, and scenery were not modified.
- Refactored the active Solo Puzzle interface into one named `PCPuzzleWorkspace` root in `src/client/ui/BlockBlastClient.client.luau`.
- Removed the old duplicate active-run dock, minimize, reset-layout, and resize controls from the Solo Puzzle surface.
- Rebuilt the PC composition toward the locked reference:
  - left column for current score, best score, combo, and real coin count
  - centered board with the existing board cells and placement logic
  - three available pieces in a tray directly beneath the board
  - right-side server score panel using the existing session leaderboard data
  - top currency/theme controls with the world still visible behind the workspace
- Added mouse-only workspace dragging from the title bar:
  - dragging begins only on `WorkspaceDragHandle`
  - board cells, pieces, buttons, and leaderboard do not start window dragging
  - releasing the mouse or closing the puzzle stops dragging
  - reopening an active run does not create new drag connections
- Added screen clamping that uses `GuiService:GetGuiInset()` and the active `UIScale` so the workspace remains recoverable at desktop edges.
- Preserved existing gameplay bindings for selecting pieces, placing pieces, blocked-placement feedback, scoring, combo display, best score, coins, server scores, Play Again, and Return Hub.
- Built `BlockBlastBattle-Day37.rbxl`.

### Current State

- Day37 is a PC workspace foundation, not a final art pass.
- The Solo Puzzle UI should now open as one centered arcade-style workspace and move as a single unit from the title bar.
- No Roblox Studio Play-mode screenshots or drag tests were captured by Codex in this session.

### Known Issues

- Runtime verification is still required in Roblox Studio because Studio automation was not available here.
- The left column does not show rank yet because the current Day37 scope did not add a persistent/global rank backend.
- Final glossy block art, mobile layout, touch dragging, gamepad dragging, resizing, saved window position, and leaderboard backend expansion are intentionally deferred.

### Required Manual Checks

1. Open `BlockBlastBattle-Day37.rbxl`.
2. Confirm Studio is signed into `CAPTINNINJATACO`.
3. Press Play and start Solo Puzzle from the PLAY button or `SoloPlayPad`.
4. Confirm the puzzle workspace opens centered.
5. Drag only from the `SOLO PUZZLE WORKSPACE` title bar and confirm the full interface moves together.
6. Try dragging from the board, piece tray, server-top panel, and action buttons; confirm the workspace does not move.
7. Place legal and illegal pieces and confirm dragging never places pieces by itself.
8. Drag the workspace into each screen edge and confirm the title/workspace remains recoverable.
9. Return to the hub, start Solo Puzzle again, and confirm no duplicate active puzzle HUD or drag behavior appears.
10. Capture a default PC puzzle screenshot and a dragged-position screenshot for Day37 review.

### Deferred

- Day38 should start only after Yoel inspects Day37 in Studio and confirms the PC workspace direction.
- Next likely work: polish board cells/piece tray visuals, add stronger selected/valid/invalid placement states, then handle separate mobile UI.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with 0 errors and 0 warnings; Selene used its cached Roblox standard library after failing to generate a fresh API dump.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day37.rbxl` passed.
- `git diff --check` passed with the repo's existing LF-to-CRLF working-copy warning.

## Day36.4 Intentional Toybox Personality and Visual Stopping Point - 2026-08-10

### Completed

- Final checkpoint for today's map work; no Day36.5 or Day37 work was started.
- Focused only on controlled toybox personality restoration after Day36.3 overcorrected into an empty, flat, dark skeleton.
- Preserved locked Day36.3 successes:
  - `HubSpawn` remains at `CFrame.new(0, 8.1, 78)`.
  - Spawn still faces negative Z.
  - `SoloPlayPad` remains at `Vector3.new(0, 6.65, 15)`.
  - `SoloPlayPad`, `QueueMode = Solo`, prompt behavior, and Solo Puzzle start behavior remain intact.
  - The debris ring, old platform `BorderStud` loop, cobblestone tile ring, skyline towers, cloud banks, oversized arches, random flowers/trees/lamps, route arrows, and yellow crossbar were not restored.
- Reworked the Day36.3 giant dark rectangle into a more deliberate connected playset silhouette:
  - replaced `ToyPlaysetMainFoundation` with named connected foundation masses for center, spawn connector, spawn landing, left activity, right activity, and rear activity areas
  - used lighter cheerful blues and purples instead of one dominant dark slab
  - added large cream/yellow edge lips to make the sidewalls read as layered toy construction
- Improved the spawn entrance:
  - widened the primary spawn-to-PLAY walkway from `28` to `32` studs
  - added two low `SpawnWelcome*Marker` blocks outside the direct camera line
  - added spawn foundation lips so the entrance feels attached to the toy set instead of a runway
- Finished the PLAY plaza as the hero landmark:
  - added `ToyPlazaCyanRing` beneath the warm round plaza for a controlled cyan outline
  - added cyan side stage blocks beside the PLAY pad
  - added a small supported PLAY sign structure with left/right supports and a gold support bar
  - lowered the PLAY billboard offset from `Vector3.new(0, 10.5, 0)` to `Vector3.new(0, 6.2, 0)` so it is less floaty while still raised above the pad
- Made surviving attractions more readable without adding new attractions:
  - Machine: added a compact back wall and gold cap owned by the machine zone
  - Bounce: added a red/white spring-base motif around the existing bounce pad
  - Launcher: added a light green launcher base owned by the launcher zone
  - Spinner: added a small purple guard owned by the spinner zone
  - Moving platform: added a short gold track base below the moving platform
  - Slide: kept Day36.3's compact slide, with no long rails restored
- Added one minimal background/atmosphere prop:
  - `RearToyBackdrop*` forms create a low-contrast distant toy backdrop behind the playset, separated from the playable route
  - no skyline tower loop, cloud bank loop, or bright structure behind PLAY was restored
- Source-level active toybox BasePart estimate:
  - Day36.3: about 85 BaseParts
  - Day36.4: about 115 BaseParts
  - hard cap was 200; Day36.4 stays well below it
- Built `BlockBlastBattle-Day36-4.rbxl`.

### Current State

- Day36.4 is intended as today's visual stopping point: cleaner than Day36.2, more cheerful and readable than Day36.3.
- The active map still needs Yoel runtime screenshot proof because source inspection is not visual proof.
- Battle and Story remain absent from the active toybox hub path.

### Known Issues

- Codex did not capture Studio screenshots in this session.
- The hub still uses native Parts/Cylinders, so it may still fall short of the polished toybox concept art until a later asset/material pass is approved.

### Required Manual Checks

1. Open `BlockBlastBattle-Day36-4.rbxl`.
2. Press Play without touching the camera and capture the immediate spawn view.
3. Confirm spawn is unobstructed, aimed toward PLAY, and the PLAY sign is readable.
4. Reset and confirm the same spawn reveal.
5. Walk from spawn to PLAY and confirm the route feels direct but less runway-like.
6. Capture a ground-level PLAY view.
7. Inspect the machine, slide, bounce, launcher, button, spinner, and moving platform zones.
8. Confirm every attraction looks owned by its platform and secondary to PLAY.
9. Capture a central attraction view and a complete aerial view with F8 HUD hide.
10. Confirm the foundation no longer reads as one giant dark rectangle.
11. Confirm the debris ring, blue overhead beams, floating rails, and yellow route crossbar did not return.
12. Test fall recovery.
13. Confirm Battle and Story remain absent.

### Deferred

- Next session should begin from Yoel's Day36.4 runtime screenshots and either approve the stopping point or make one specific visual correction.
- Larger polish should wait for an approved art/asset direction rather than adding random Parts.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with 0 errors and 0 warnings; Selene used its cached Roblox standard library after failing to generate a fresh API dump.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day36-4.rbxl` passed.
- `git diff --check` passed with the repo's existing LF-to-CRLF working-copy warning.

## Day36.3 Runtime Debris Tracing and Structural Simplification - 2026-08-10

### Completed

- Focused only on Day36.3 runtime debris tracing and subtraction-first hub cleanup; no UI, gameplay, DataStore, monetization, leaderboard, rename, or Day37 work was done.
- Preserved the locked runtime transforms and behavior:
  - `HubSpawn` remains at `CFrame.new(0, 8.1, 78)`.
  - Spawn still faces the default forward direction toward negative Z.
  - `SoloPlayPad` remains at `Vector3.new(0, 6.65, 15)`.
  - The spawn-to-PLAY horizontal relationship remains roughly 63 studs straight forward.
  - `SoloPlayPad`, `QueueMode = Solo`, the existing prompt, and Solo Puzzle start behavior remain intact.
- Traced the Day36.2 debris ring to active generators other than `ScatteredToyBrick*`:
  - `makeToyDiskPlatform()` generated 16 `BorderStud` toy blocks around every disk platform; with 7 disk platforms this created 112 loose-looking gray/gold perimeter blocks.
  - `ToyboxStoneTile*` generated 12 brown/cobblestone surface fragments around the central plaza.
  - `ToyboxRoundLamp*`, `ToyFlower*`, `ToyTree*`, cloud puffs, skyline towers/caps, and arch studs added small repeated pieces around the map.
  - `BlueToySlide` generated 7 large raised blue segments and 2 long rails, which likely read as overhead beams.
  - `PlazaNorthGold`, `PlazaSouthGold`, `PlayPathArrow`, and `MovingPuzzlePlatform` created yellow route-crossing pieces.
- Removed the active debris generators instead of hiding their Parts:
  - all disk `BorderStud` generation
  - `ToyboxStoneTile*`
  - plaza gold trim bars
  - route arrows
  - toy arches and their studded columns/beams
  - high-score facade
  - trees, lamps, flowers, cloud banks, and skyline towers/caps
  - unused helper functions that only supported the removed clutter
- Replaced the Day36.2 foundation fragments with two clean foundation masses:
  - `ToyPlaysetMainFoundation`
  - `ToyPlaysetSpawnFoundation`
- Reduced active platform masses:
  - removed separate `SpawnEntranceIsland` and `ScoreboardIsland`
  - kept compact central, machine, fun, launch, and slide platform pads
  - pulled attraction pads inward so they sit on the main foundation silhouette
- Standardized the route:
  - kept the main spawn-to-PLAY walkway as the consistent primary path
  - shortened secondary walkways and ensured they terminate at compact attraction zones
  - renamed the rear route from `PlayToScoresPath` to `PlayToRearAttractionsPath`
- Improved PLAY readability:
  - removed the `ToyboxPlayArch` that could compete with or obscure PLAY
  - raised the world PLAY billboard from `Vector3.new(0, 7.2, 0)` to `Vector3.new(0, 10.5, 0)`
  - kept the cyan PLAY pad as the strongest visual accent
- Simplified attraction presentation:
  - compacted `BlockDropMachine` (later renamed `GumballMachine`) and reduced internal visible blocks from 10 to 4
  - compacted `BlueToySlide` from 7 segments plus 2 rails to 4 shorter segments and no long rails
  - moved bounce, launcher, button, spinner, and moving platform closer to the main foundation
  - shrank `ToyboxSpinnerPlatform` and `MovingPuzzlePlatform`
- Source-level generated BasePart estimate:
  - Day36.2 active toybox path: about 366 BaseParts
  - Day36.3 active toybox path: about 85 BaseParts
  - estimated reduction: about 281 BaseParts
- Built `BlockBlastBattle-Day36-3.rbxl`.

### Current State

- The active hub is intentionally much simpler and should be easier to judge in Studio.
- Battle and Story remain absent from the active toybox hub return path.
- The active toybox path now contains no generators named `BorderStud`, `ToyboxStoneTile`, `ToyboxColorZone`, `ScatteredToyBrick`, `ToySkyline`, `ToyboxCloud`, `ToyTree`, `ToyFlower`, `ToyboxRoundLamp`, `ToyboxPlayArch`, `ToyboxScoresArch`, `ToyboxFidgetArch`, `PlazaNorthGold`, `PlazaSouthGold`, `HighScoresFace`, `PlayPathArrow`, or `SpawnPathArrow`.

### Known Issues

- Codex did not have Roblox Studio screenshot automation in this session, so Day36.3 still requires Yoel's runtime screenshots.
- Source inspection confirms generator removal and geometry reduction, but source inspection is not visual proof.

### Required Manual Checks

1. Open `BlockBlastBattle-Day36-3.rbxl`.
2. Press Play and capture the immediate spawn view without moving the camera.
3. Confirm PLAY remains visible and the raised PLAY lettering is not hidden by the cyan pad.
4. Reset and confirm the same spawn view.
5. Walk from spawn to PLAY and confirm the route is uninterrupted.
6. Capture a normal ground-level PLAY view.
7. Walk to bounce, launcher, button, spinner, moving platform, slide, and machine zones.
8. Confirm all secondary paths terminate at real attractions.
9. Capture a complete aerial view with F8 HUD hide.
10. Confirm no ring of loose gray/yellow/brown/rainbow debris remains.
11. Confirm no large blue overhead beams or yellow crossbar dominate the route.
12. Test fall recovery.
13. Confirm Battle and Story remain absent.

### Deferred

- If Day36.3 still looks too plain, the next approved visual pass should use better art direction and assets, not more random Parts.
- Later work should restore any desired leaderboard/signage only after the core toy playset silhouette is approved.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with 0 errors and 0 warnings; Selene used its cached Roblox standard library after failing to generate a fresh API dump.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day36-3.rbxl` passed.
- `git diff --check` passed with the repo's existing LF-to-CRLF working-copy warning.

## Day36.2 Toy Playset Foundation Cohesion - 2026-08-10

### Completed

- Focused only on the Day36.2 map-foundation cohesion checkpoint; no UI, gameplay, leaderboard, monetization, or new-attraction work was done.
- Preserved the Day36.1 spawn correction:
  - `HubSpawn` remains at `CFrame.new(0, 8.1, 78)`.
  - The spawn faces the default forward direction toward negative Z.
  - `SoloPlayPad` remains centered at `Vector3.new(0, 6.65, 15)`, keeping the straight spawn-to-PLAY route at roughly 63 studs.
  - The `SoloPlayPad` name, `QueueMode = Solo` attribute, prompt, and billboard remain intact.
- Classified the active toybox footprint:
  - essential gameplay zones: spawn, PLAY, `SoloPlayPad`, fall recovery, and attraction interactables
  - necessary connectors: spawn-to-PLAY path and secondary routes to scores, machine, fun, and launch areas
  - useful visual structures: scoreboard, machine, slide, bounce pad, launcher, press button, spinner, moving platform, trees, lamps, flowers, clouds, and muted skyline
  - redundant/noisy decoration: four large `ToyboxColorZone*` floor patches, excess plaza tiles, side gold plaza trim, several detached fences, excess flowers/lamps/trees, and bright skyline towers
  - loose debris: all 12 `ScatteredToyBrick*` objects
- Built a shared shaped foundation using thick toy-plastic pieces:
  - `ToyPlaysetFoundationSpine`
  - `ToyPlaysetFoundationCrossbar`
  - `ToyPlaysetRearFoundationStep`
- Consolidated platform layout:
  - reduced oversized spawn, scoreboard, machine, fun, launch, and slide island radii
  - overlapped major pads with wider foundation pieces so the hub reads as one constructed playset instead of separate thin floating disks
  - widened the main spawn-to-PLAY path and used the same marble/water-deep treatment for the main route
- Cleaned the central plaza:
  - reduced the round plaza diameter
  - removed large colored floor-zone rectangles
  - reduced radial stone tiles from 30 to 12
  - removed the secondary PLAY path arrow
  - kept one clear forward arrow on the main route
- Integrated PLAY into a thicker built platform:
  - kept the cyan PLAY surface as the primary focal accent
  - widened the white lip and orange base beneath it so it reads as a constructed button assembly rather than a plain slab
- Reduced the yellow machine's dominance:
  - moved it farther right/rear
  - reduced its base from `32x14x22` to `24x10x16`
  - reduced internal floating blocks from 22 to 10
  - kept the machine button and animation behavior functional
- Removed all loose outer `ScatteredToyBrick*` debris.
- Cleaned boundaries:
  - tightened spawn rails/fences
  - removed detached Fun Zone and Launch back fences
  - kept the Score back fence as a real rear-edge safety/readability boundary
- Simplified decoration and background:
  - reduced trees from 6 to 4
  - reduced lamps from 14 to 10
  - reduced flowers from 20 to 14
  - reduced skyline towers from 4 to 3, moved them farther back, and muted their colors
- Built `BlockBlastBattle-Day36-2.rbxl`.

### Current State

- The newest build artifact is `BlockBlastBattle-Day36-2.rbxl`.
- Source/math inspection confirms the spawn-to-PLAY horizontal vector remains `(0, 0, -63)`, so the initial route direction is preserved.
- Battle and Story remain absent from the active toybox hub path.

### Known Issues

- Roblox Studio runtime screenshots were not captured by Codex in this session; Yoel must visually verify Day36.2 in Play mode.
- The hub still uses native Roblox Parts and Cylinders, so it will not perfectly match the high-fidelity concept art without later mesh/material/asset polish.

### Required Manual Checks

1. Open `BlockBlastBattle-Day36-2.rbxl`.
2. Press Play without moving the camera and confirm PLAY is still visible immediately.
3. Confirm the spawn platform is unobstructed and still faces the PLAY route.
4. Walk straight from spawn to PLAY and verify the route reads as one consistent main path.
5. Capture spawn, player-height plaza, and aerial screenshots with F8 HUD hide.
6. Confirm the hub reads as one cohesive toy playset, not detached thin platforms.
7. Confirm all attraction mechanics still function: bounce, launcher, press button, spinner, moving platform, and slide.
8. Confirm loose edge debris is gone and rails/fences end cleanly.
9. Confirm fall recovery still returns to the safe hub spawn.

### Deferred

- Do not start Day37 until Day36.2 screenshots confirm the foundation cohesion direction is acceptable.
- Later visual polish should focus on high-quality mesh/material treatment and screenshot-based composition tuning.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with 0 errors and 0 warnings; Selene used its cached Roblox standard library after failing to generate a fresh API dump.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day36-2.rbxl` passed.
- `git diff --check` passed with the repo's existing LF-to-CRLF working-copy warning.

## Day36.1 Runtime Map and Spawn Correction - 2026-08-10

### Completed

- Focused only on the runtime map/spawn failures Yoel reported from Day36.
- Identified the giant dark cylinder source:
  - Day36 `makeToyDiskPlatform()` created cylinder Parts for playset foundations.
  - The function rotated both base and top cylinders by 90 degrees, turning intended flat platforms into huge sideways barrels.
  - Active fidget cylinders for bounce, launcher, press button, plaza, and spinner had the same unnecessary flat-pad rotation pattern.
- Removed the active toybox cylinder rotations so platform/fidget cylinders render as flat pads instead of camera-blocking barrels.
- Reduced the visual dominance of legitimate platform foundations:
  - lowered foundation heights
  - changed giant dark foundation colors to softer toy-blue, purple, green, tan, and gold support colors
  - kept dark values limited to smaller trim/support roles
- Simplified the Day36 layout:
  - removed the four low outer `MainFloor*` trim blocks that no longer matched the invisible backing floor
  - reduced loose `ScatteredToyBrick*` count from 24 to 12
  - removed secondary Fun Zone and Machine arrows
  - reduced the skyline from 7 bright towers to 4 lower-contrast background towers
- Clarified the spawn-to-PLAY route:
  - spawn remains at `CFrame.new(0, 8.1, 78)`, facing default forward toward negative Z
  - PLAY remains centered at approximately `Vector3.new(0, 6.65, 15)`
  - route distance is roughly 63 studs straight forward along negative Z
  - kept only the main route arrows from spawn and PLAY
- Made PLAY more recognizable:
  - reduced the cyan pad from `40x24` to `34x20`
  - changed the overhead billboard title from `SOLO PUZZLE` to `PLAY`
  - kept `SoloPlayPad`, its `QueueMode = Solo` attribute, and the existing prompt behavior
- Built `BlockBlastBattle-Day36-1.rbxl`.

### Current State

- Day36.1 should remove the giant dark cylinder obstruction shown in Yoel's Day36 runtime screenshots.
- The map should be less crowded than Day36 while preserving the larger toy-playset direction.
- No puzzle UI, mobile UI, leaderboard, gameplay, monetization, DataStore, or new attraction work was done.

### Known Issues

- Studio runtime verification was not available to Codex in this session; Yoel still needs to confirm the immediate spawn view in Play mode.
- Remaining visual polish depends on screenshots from `BlockBlastBattle-Day36-1.rbxl`.

### Required Manual Checks

1. Open `BlockBlastBattle-Day36-1.rbxl`.
2. Press Play without moving the camera and confirm no giant dark cylinder blocks the view.
3. Confirm PLAY is visible from spawn.
4. Reset and confirm the same spawn reveal.
5. Walk straight from spawn to PLAY and confirm the path is obvious.
6. Capture spawn view, central player-height view, and aerial view with F8 HUD hide.
7. Confirm no large cylinders pass through player platforms.
8. Confirm fall recovery still returns to the hub.
9. Confirm Battle and Story prompts/routes remain absent.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with 0 errors and 0 warnings; Selene used its cached Roblox standard library after failing to generate a fresh API dump.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day36-1.rbxl` passed.
- `git diff --check` passed with the repo's existing LF-to-CRLF working-copy warning.

## Day36 Map and Spawn Correction - 2026-08-10

### Completed

- Focused only on the active toybox hub map/spawn path in `src/server/world/HubBuilder.luau`.
- Identified the Day35 floating debris source:
  - `buildToyboxHub()` called the older `buildBackground(hub)` helper.
  - `buildBackground()` generates `FloatingRock*`, slate/stone distant silhouettes, and floating scenery originally intended for the fantasy island direction.
- Removed that obsolete background call from the active toybox hub path.
- Kept the old `buildBackground()` function only for the inactive legacy/non-toybox route.
- Converted `ToyboxMainPlayFloor` into invisible, non-colliding metadata/safety backing so it no longer renders as the huge pale slab.
- Added a designed playset layout:
  - `CentralPlaysetIsland`
  - `SpawnEntranceIsland`
  - `ScoreboardIsland`
  - `MachineIsland`
  - `FunZoneIsland`
  - `LaunchIsland`
  - `SlideTowerIsland`
- Added deliberate thick walkways:
  - `SpawnToPlayPath`
  - `PlayToScoresPath`
  - `PlayToMachinePath`
  - `PlayToFunPath`
  - `PlayToLaunchPath`
- Moved the player spawn to `CFrame.new(0, 8.1, 78)` facing down the main path toward the PLAY attraction.
- Moved the obstructing spawn lip away from the immediate spawn camera line.
- Raised the plaza, tiles, trees, flowers, lamps, bounce pad, launcher, spinner, moving platform, and slide staging onto the new platform heights so they no longer read as floating loose pieces.
- Added perimeter rails/fences, path arrows, toy skyline towers, and stronger zone framing.
- Reduced washed-out lighting by enabling global shadows, lowering brightness/exposure, reducing bloom, and increasing contrast slightly.
- Preserved the active `SoloPlayPad`, safe `HubSpawn`, invisible void recovery platform, Solo-first feature flags, and disabled Battle/Story state.
- Built `BlockBlastBattle-Day36.rbxl`.

### Current State

- Day36 should open with a cleaner spawn entrance and a more cohesive toy-playground composition than Day35.
- Studio automation was still unavailable in this session, so the new spawn presentation and map view are source/build verified only.
- The active hub no longer intentionally displays the old floating fantasy rocks or slate silhouettes.

### Known Issues

- Needs manual Studio Play-mode screenshots from spawn, ground-level map view, and aerial F8 view.
- The design still uses native Parts/Cylinders rather than custom meshes, so the final toybox polish will depend on screenshot review.
- Puzzle UI, mobile UI, leaderboards, gameplay balance, and new modes were intentionally untouched.

### Required Manual Checks

1. Open `BlockBlastBattle-Day36.rbxl`.
2. Press Play and confirm the player spawns on the entrance island facing the PLAY path.
3. Confirm no large prop blocks the camera immediately after spawn.
4. Reset and confirm respawn returns to the same staged view.
5. Walk from spawn to PLAY, then to high scores, machine, bounce pad, launcher, press button, spinner, moving platform, and slide.
6. Walk off several edges and confirm invisible fall recovery returns to the hub without showing recovery geometry.
7. Use F8 to hide HUD and capture spawn, player-height, and aerial screenshots.
8. Confirm Battle and Story prompts/routes remain absent.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with 0 errors and 0 warnings; Selene used its cached Roblox standard library after failing to generate a fresh API dump.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day36.rbxl` passed.
- `git diff --check` passed with the repo's existing LF-to-CRLF working-copy warning.

## Day35 Visual Proof and Matching Pass - 2026-08-10

### Day34 Mismatch List

- Image 1 map: Day34 still depended on one broad rectangular toy floor, sparse props, and primitive scattered bricks instead of the dense toybox plaza shown in the reference.
- Image 1 map: the PLAY pad, high-score wall, fidget toys, and machine existed, but the central composition did not yet read like a cohesive front-page Roblox toy playground.
- Image 2 PC UI: Day34 had the correct data connections, but the board, score, hand tray, and server leaderboard still behaved like one resizable utility window rather than the deliberate score-left / board-center / leaderboard-right composition.
- Image 3 mobile UI: Day34 compact mode was mostly a scaled desktop layout; the piece tray and best-score hierarchy were not sufficiently mobile-first.
- Visual assets: no Day34 PNGs were created, uploaded, or wired into Roblox asset IDs.
- Runtime proof: Studio MCP/screenshot automation was not available in this Codex session, so Day34 visual inspection remains manual.

### Completed

- Rebuilt the active toybox hub composition in `src/server/world/HubBuilder.luau` without restoring Battle/Story:
  - reduced the empty main floor footprint
  - added a raised circular puzzle plaza with colored trims
  - added stronger spawn and PLAY staging
  - added `ToyboxPlayArch`, `ToyboxScoresArch`, and `ToyboxFidgetArch`
  - added rail details, colorful trees, flower balls, denser toy bricks, and more lamps
  - reused the high-score wall, block-drop machine, slide, bounce pad, launcher, press button, spinner, moving platform, and cloud scenery
  - added distant background scenery through the toybox path so the hub has more depth
- Polished existing fidget interactions in source:
  - bounce pad now has per-character cooldown, particles, and sound
  - launcher now has per-character cooldown, particles, and sound
  - pressable button now has particles and sound
  - existing spinner, moving platform, and slide remain active
- Reworked the Solo puzzle HUD in `src/client/ui/BlockBlastClient.client.luau`:
  - desktop layout now uses a large central board, left score/combo column, bottom three-piece tray, and right current-server leaderboard card
  - mobile compact layout now keeps score/best at the top, board central, larger touch-friendly piece previews below, and a compact leaderboard strip
  - board cells now keep glossy per-color gradients so placed pieces remain bright
  - piece previews scale from their actual container size instead of a fixed 44px box
- Created reproducible Day35 local PNG exports in `assets/ui/day35/`:
  - `panel-shine-512x256.png`
  - `combo-burst-512.png`
  - `toy-block-pattern-512.png`
  - `rank-medals-512x192.png`
- Added `tools/design/generate_day35_assets.py` as the source generator for those exported PNGs.
- Built `BlockBlastBattle-Day35.rbxl`.

### Current State

- Day35 is a visible source/build correction checkpoint over Day34, not a Studio-proven final match.
- Real gameplay data remains connected for score, best score, coins, combo, and current-server scores.
- Battle and Story remain absent from the active hub flow.
- The new PNGs are local Roblox-ready upload candidates only; the active UI still uses native Roblox fallback components until asset IDs are uploaded and mapped.

### Known Issues

- Studio Play-mode screenshots were not captured because no Studio MCP or screen-capture control was exposed to this session.
- The map still uses Roblox-native Parts rather than custom meshes, so it will not yet match the concept image's bevel/render quality exactly.
- The PC and mobile UI are closer in layout but still need in-Studio screenshot comparison against the references.
- Global and weekly leaderboards remain intentionally out of scope for Day35.

### Required Manual Screenshots

1. Open `BlockBlastBattle-Day35.rbxl`.
2. Capture normal spawn view facing the PLAY pad.
3. Capture a three-quarter aerial map view with the HUD hidden using F8.
4. Start Solo and capture the desktop puzzle UI.
5. Capture a line-clear/combo moment.
6. Capture out-of-moves/results and Play Again.
7. Capture a phone portrait emulation view with the board and pieces visible.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with 0 errors and 0 warnings; Selene used its cached Roblox standard library after failing to generate a fresh API dump.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day35.rbxl` passed.
- `git diff --check` passed with the repo's existing LF-to-CRLF working-copy warnings.

## Day34 Reference Reconstruction - 2026-08-09

### Completed

- Treated the three attached references as the official visual target and saved the extracted specification in `docs/DAY34_VISUAL_SPEC.md`.
- Added `ExperienceConfig.World.UseToyboxHub = true` so the active hub uses the new toybox path while preserving previous hub code for rollback/reference.
- Replaced the visible Day33 fantasy hub direction with a source-built toybox playground:
  - large flat central toy plaza
  - oversized cyan `PLAY` pad
  - safe spawn deck
  - `SoloPlayPad` with server-owned Solo prompt
  - chunky `HIGH SCORES` wall
  - block-drop machine filled with colorful rotating toy blocks
  - blue slide
  - red bounce pad
  - green launcher pad
  - purple spinner platform
  - moving puzzle platform
  - pressable button reaction
  - scattered toy bricks, lamps, clouds, and colorful zones
- Preserved safe spawn and void recovery behavior.
- Preserved Solo-first configuration; Battle and Story remain disabled and absent from active prompts/routes/arenas.
- Rebuilt the gameplay board UI toward the PC and mobile references:
  - larger default 1000x650 active puzzle overlay
  - dark navy rounded board frame with cyan stroke
  - rounded stroked board cells
  - large score card
  - best-score label
  - coin chip
  - combo badge
  - darker rounded piece tray/cards
  - concept-style `SERVER TOP` leaderboard panel
  - responsive mobile stacking with score above board and hand tray below board
- Added a real current-server leaderboard foundation:
  - server owns entries
  - scores come from server-authoritative placement/scoring
  - top list is capped and broadcast to Solo players
  - no client score submission was added
- Built `BlockBlastBattle-Day34.rbxl`.

### Asset Notes

- No Roblox asset uploads were performed.
- No full-screen screenshot was used as the working UI.
- Day34 uses Roblox-native `Frame`, `UIStroke`, `UICorner`, `UIGradient`, text, and Part geometry.
- Future PNG/nine-slice assets should follow `docs/DAY34_VISUAL_SPEC.md`; upload/import remains a manual Roblox account action unless Studio upload automation becomes available.

### Current State

- Day34 is the first functional reconstruction of the chosen direction, not the final pixel-perfect version.
- The toybox map should now read much closer to Image 1 than the prior floating terrain hub.
- The PC puzzle UI should now read closer to Image 2: score left, large board center, server leaderboard right, strong dark/cyan panels.
- The mobile layout should now read closer to Image 3: score top, board center, touch-friendly tray lower on the screen.

### Known Issues

- Studio Play-mode screenshots were not captured in this Codex session; visual proof still needs manual screenshots.
- UI pieces are still made from Roblox Frames rather than uploaded glossy PNG/nine-slice art, so they will not yet match the rendered concept exactly.
- The map uses primitive Parts and cylinders; it needs bevel/mesh polish, denser background structures, more avatars/social staging, and better material tuning.
- Global and weekly OrderedDataStore leaderboards are still not implemented.
- Some legacy internal names remain (`BattleStart`, `BattleResult`, `LeaveBattle`) to avoid breaking existing remote contracts during the visual checkpoint.

### Required Manual Screenshots

1. Spawn view facing the central PLAY pad.
2. Main toybox plaza from player height.
3. Three-quarter aerial view of the whole toybox.
4. PC puzzle UI during a Solo run.
5. Mobile/portrait puzzle UI during a Solo run.
6. A line-clear or combo moment.
7. Server leaderboard panel after at least one score.

### Recommended Day35 Priorities

1. Compare the required screenshots against the three references and fix the largest visual mismatches.
2. Add stronger glossy asset treatment or uploaded nine-slice panel assets if Roblox asset upload is available.
3. Improve board piece drag/touch feel and add stronger line-clear/score animations.
4. Add all-time and weekly leaderboard architecture with OrderedDataStores.
5. Increase toybox density with more polished structures while profiling mobile part count.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with 0 errors and 0 warnings; Selene used its cached Roblox standard library after failing to generate a fresh API dump.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day34.rbxl` passed.

## Day33 Solo-First Pivot - 2026-08-09

### Completed

- Pivoted the active product direction from Battle-first to Solo-first without deleting reusable Battle/Story source.
- Added `src/shared/game/ExperienceConfig.luau` as the central feature flag module:
  - Solo enabled.
  - Battle disabled.
  - Story disabled.
  - Custom Lab disabled for the current live flow.
  - Battle routes, Story routes, and battle arenas disabled from world generation.
- Fixed the likely unsafe spawn cause from Day32: `HubSpawn` was positioned over lumpy generated Terrain near the central island instead of on a dedicated clean surface.
- Added a raised, flat `SafeSoloSpawnPlaza` and moved `HubSpawn` to `CFrame.new(0, 12.8, 42)` facing the central puzzle core.
- Kept the void recovery platform invisible and pointed it at the same safe `HubSpawn`.
- Updated fallback hub generation so a future hub-build error creates a Solo pad and safe spawn instead of bringing back Battle/Story pads and fallback arenas.
- Added a visible `SoloPlayPad` / `SoloPuzzlePortal` with a server-owned ProximityPrompt.
- Disabled active Battle/Story prompt connections when their feature flags are off.
- Made the primary Play button request server-authoritative Solo play immediately instead of joining the Battle queue.
- Made `PlayAgain` restart Solo instead of queueing Battle.
- Added server-side Solo session handling through the existing validated puzzle state, placement, score, reward, result, and save flow.
- Kept client placement, score, rewards, XP, coins, best score, cosmetics, settings, and purchase authority on the server.
- Updated HUD text away from Battle/arena-first language:
  - title now reads `Solo Puzzle`
  - subtitle now reads `Beat your best score`
  - resource bar shows Best Score instead of Wins/Stars while Solo-first flags are active
  - tutorial text now describes solo scoring instead of pressuring rivals
- Removed active Modes UI exposure by config while preserving the mode menu source for later reuse.
- Built `BlockBlastBattle-Day33.rbxl`.

### Solo Puzzle Loop Audit

- Confirmed by source/build:
  - `Play` sends `Queue` remote mode `Solo`.
  - Server accepts `Solo` only because `ExperienceConfig.Modes.Solo = true`.
  - Server creates the board with `Grid.create()`.
  - Server creates three pieces with `Blocks.createHand(..., Config.InventorySize, ...)`.
  - Placement requests are rate-limited and payload-validated server-side.
  - Legal placements use `Grid.place`.
  - Illegal placements fire `InvalidPlace` without changing score.
  - Row/column clears use `Grid.clearLines`.
  - Combos add `Config.ComboBonusPoints`.
  - Score updates on the server and pushes to clients through `State`.
  - `BestScore` updates when the current score beats saved best.
  - Out-of-moves uses `Grid.hasAnyMove`.
  - Results include score, lines cleared, best combo, coins, XP, and best-score delta.
  - `Play Again` now requests a new Solo run.
  - Profile save/load still uses `BlockBlastProfilesV1`; DataStore keys were not renamed.
- Present but not Studio-verified in this checkpoint:
  - Initial spawn, reset spawn, and fall recovery in real Play mode.
  - Mouse/touch/controller board placement behavior.
  - Result panel timing after out-of-moves.
  - Rejoin with saved best score and settings.
  - Mobile screen fit.
- Missing or future:
  - Server/global/weekly OrderedDataStore leaderboards.
  - A final polished solo board UX pass.
  - Dedicated solo tutorial/onboarding flow.
  - Final non-infringing product name/branding.

### Leaderboard Status

- Existing leaderstats include `Coins`, `XP`, `Level`, `Wins`, `BestScore`, `BattleScore`, and `StoryStars`.
- `BestScore` is functional in code and saved inside the existing player profile payload.
- In-run leaderboard currently shows only players in the same active session, which for Solo means mostly the current player.
- No global or weekly OrderedDataStore leaderboard system is currently implemented.
- Next leaderboard work should add server-authoritative OrderedDataStore writes with throttling, anti-spam protection, and a readable hub leaderboard display.

### Current State

- Day33 is a Solo-first foundation build, not a final art or gameplay polish pass.
- Battle/Story systems are preserved in source but hidden/inactive through `ExperienceConfig`.
- The main hub is simpler: one central area, one safe spawn plaza, one obvious Solo play portal, no active Battle/Story route endpoints, no visible match arenas.
- Roblox Studio Play-mode testing was not performed in this Codex session; Studio validation remains required.

### Known Issues

- The custom board UI still carries some legacy variable/function names such as BattleStart/BattleResult effect kinds and `LeaveBattle`; these are contract names and were intentionally not renamed during Day33.
- HomePanel source still contains old Battle/Story labels, but the active client path force-hides the HomePanel and hides Modes by config.
- The map is still source-generated, so the solo lounge needs real player-height screenshots before the next visual polish pass.
- Global and weekly leaderboards are not built yet.

### Recommended Day34 Priorities

1. Studio Play-mode validation of Day33 spawn, reset, fall recovery, and Solo play start. This proves the pivot works in the real client.
2. Polish the solo board interaction and results loop. This is now the actual product core.
3. Add server/global/weekly leaderboard foundation. Best score exists, but players need visible competition.
4. Clean up legacy Battle naming in remotes/UI internals only after behavior is stable. Rename risk is lower once Day33 is proven.
5. Begin a compact solo lounge art pass from real player-height screenshots.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with 0 errors and 0 warnings; Selene used its cached Roblox standard library after failing to generate a fresh API dump.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day33.rbxl` passed.
- `git diff --check` passed, with Git line-ending warnings only.

## Day32 Visual Cleanup - 2026-08-09

### Completed

- Used the user-provided Day31 Play-mode aerial screenshot as the visual source of truth.
- Confirmed the Day31 fallback fix worked, but the real hub composition still failed due to oversized world text, visible safety planes, repeated procedural debris, weak destination spacing, and arena label clutter.
- Focused only on hub composition cleanup; did not redesign screen UI, rename the game, add monetization, change DataStores, or rewrite gameplay.
- Tightened all `BillboardGui` behavior in `src/server/world/HubBuilder.luau`:
  - default destination labels reduced from `250x88` to `170x62`
  - `AlwaysOnTop` disabled
  - `MaxDistance = 105` for primary labels
  - blank subtitles hide their secondary label
  - status labels reduced to `190x66`
  - status labels limited to `MaxDistance = 55`
- Removed duplicated arena/player world billboards:
  - `PlayerSpawnA` no longer shows `PLAYER A / Your board`
  - `PlayerSpawnB` no longer shows `PLAYER B / Your board`
  - `ReturnHubPad` no longer shows `HUB / Return after match`
  - `BattleArenaSpawn` no longer shows `ARENAS / Match starts here`
- Kept essential close-range queue status labels on `BattleQueuePad` and `StoryQueuePad`.
- Identified the visible translucent square as safety/recovery-style geometry, primarily the large `VoidRecoveryPlatform` and hidden safe walk/landing surfaces seen from aerial distance.
- Changed `VoidRecoveryPlatform` transparency from `0.9` to `1` while preserving collision/touch recovery behavior.
- Kept central and route safe surfaces invisible with collision enabled for reliable traversal.
- Reduced procedural clutter:
  - cloud banks reduced from 18 to 7
  - floating rocks reduced from 12 small evenly distributed pieces to 5 larger framing pieces
  - distant skyline silhouettes reduced from 7 to 4 and moved farther out
  - removed global `DistantBirds` and `DriftingLeaves` particle anchors that produced repeated white clusters around the view
- Improved central island composition:
  - enlarged the terrain island mass
  - added additional cliff blocks/terrace mass
  - enlarged the invisible safe upper surface to match the wider hub footprint
  - repositioned trees, flowers, benches, and waterfalls around a wider plaza perimeter
- Improved Brick Core dominance:
  - shortened the world title to `BRICK CORE`
  - enlarged the pedestal, upper pedestal, pillars, crown, core blocks, and energy beam
  - kept glow/particles restrained instead of depending on huge text
- Improved Battle route readability:
  - moved the Battle endpoint farther from the central island
  - enlarged the temporary Battle landing island
  - widened Battle route/landing lanes
  - moved the Battle gate, queue pad, bunting, lamps, and versus sculpture into a clearer route sequence
- Improved Story route readability:
  - moved the Story endpoint farther out and enlarged it
  - lengthened the Story bridge and path
  - moved the Story portal, arches, tree, rocks, fragments, and lamps to reduce overlap
- Moved match arenas farther from the social hub by changing `ARENA_CENTERS` from roughly `z=-210` to roughly `z=-430`.
- Built `BlockBlastBattle-Day32.rbxl`.

### World Label Audit

- `addBillboard` primary labels: now medium range, smaller size, no AlwaysOnTop.
- `BattleQueuePad.QueueStatus`: retained close-range queue status only.
- `StoryQueuePad.StoryStatus`: retained close-range Story status only.
- `HubSpawn.Label`: retained as a modest `BRICK CORE` label with no subtitle.
- `BattlePortal.Label` and `StoryPortal.Label`: retained through `makePortal` but distance-limited by the helper.
- Route banners and gate/arch SurfaceGui labels: retained as local environmental signage.
- Arena scoreboard SurfaceGui text: retained on the arena object, but arenas were moved away from the hub view.
- Arena spawn/return BillboardGui labels: removed.

### Current State

- Technical validation passes locally.
- Visual approval still requires real Studio screenshots from Day32.
- Press F8 in Studio Play mode to hide the custom screen HUD before reviewing the map.

### Required Manual Views

1. Normal spawn view facing the Brick Core.
2. Plaza view facing the Battle entrance.
3. Plaza view facing the Story entrance.
4. Three-quarter aerial view.
5. Extreme aerial diagnostic view to confirm world labels no longer overlap.

### Known Visual Risks

- The hub is still source-generated from Terrain and Parts, not a hand-authored Studio art scene or imported environment kit.
- The central terrain may still need more authored terrace shaping after player-height screenshots.
- Battle and Story endpoints are improved temporary platforms, not final full destination islands.

## Day31 Runtime Map Mismatch Fix - 2026-08-09

### Completed

- Investigated the user-provided Day30 Play-mode screenshot as the runtime source of truth and confirmed it showed the fallback hub, not the claimed Day30 hub.
- Confirmed `BlockBlastBattle-Day30.rbxl` existed at `C:\Users\Bear4\Documents\Codex\2026-07-28\build\outputs\block-blast-battle\BlockBlastBattle-Day30.rbxl`, size `118277`, modified `2026-08-09 7:58:04 AM`.
- Confirmed Rojo mapped the edited `src/server/world/HubBuilder.luau` into the built place by building an inspection `.rbxlx` and finding `CentralHubIsland` and `BrickCoreLandmark` in the generated module source.
- Found the actual runtime cause in Roblox Studio logs: `The current thread cannot write 'Technology' (lacking capability RobloxScript)`.
- Identified the failing code path:
  - Runtime entry point: `src/server/services/GameServer.server.luau`
  - Active builder require: `require(script.Parent.Parent.world.HubBuilder)`
  - Failing call: `pcall(HubBuilder.build)`
  - Fallback path: `buildFallbackHub(hubPartsOrError)`
  - Protected write: `Lighting.Technology = Enum.Technology.Future` in `HubBuilder.configureLighting()`
- Replaced direct Lighting property writes with `safeLightingSet()` for runtime-safe lighting configuration.
- Removed the protected `Lighting.Technology` write entirely.
- Added successful-build cleanup for `Workspace.BootstrapHubSafetyFloor` and `Workspace.BootstrapHubSpawn` so bootstrap safety geometry cannot remain visible after the real hub builds.
- Preserved fallback behavior if a future hub error occurs before successful construction.
- Built the corrected next unused artifact: `BlockBlastBattle-Day31.rbxl`.

### Runtime Object Mapping From Rejected Screenshot

- Enormous rectangular grass platform: `Workspace.BootstrapHubSafetyFloor`, resized and recolored by `buildFallbackHub()`.
- Flat gray central baseplate: `Workspace.BlockBlastHub.FallbackArenaFloor`.
- Large cyan/purple glowing pads: `Workspace.BlockBlastHub.BattleQueuePad` and `Workspace.BlockBlastHub.StoryQueuePad` created by `buildFallbackHub()`.
- Scattered colored cubes: `Workspace.BlockBlastHub.FallbackRainbowBlock*`.
- Glowing rectangles: `Workspace.BlockBlastHub.FallbackFlower*`.
- Primitive floating box at the back: fallback arena/fallback warning geometry, not the Day30 central hub.

### Evidence

- Studio logs repeatedly showed fallback warnings with the same cause: `The current thread cannot write 'Technology' (lacking capability RobloxScript)`.
- Built `.rbxlx` inspection showed Day31 includes `safeLightingSet`, `removeBootstrapSafetyParts`, `CentralHubIsland`, and `BrickCoreLandmark`.
- No duplicate authoritative hub path was found; the fallback was created only because `HubBuilder.build()` errored.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with `0 errors`, `0 warnings`, `0 parse errors`.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day31.rbxl` passed.
- `git diff --check` passed with line-ending warnings only.

### Current State

- The source-of-truth mismatch is fixed in code, but visual approval still requires a new Play-mode screenshot from `BlockBlastBattle-Day31.rbxl`.
- Press F8 in Studio Play mode to hide/show the custom HUD during map inspection.
- If fallback appears again, Studio Output should now show a different warning; the previous `Lighting.Technology` blocker is removed.

## Day30 Visual Correction - 2026-08-09

### Completed

- Treated the user-provided Day29 Play-mode screenshot as the source of truth and marked Day29 as visually rejected.
- Identified the main visual failure: the generated world still read as one flat green rectangular plate, detached gray plates, scattered glowing cubes, and prototype primitive decoration instead of a polished floating hub.
- Preserved Day28 UI work and Day29 build/commit; did not overwrite `BlockBlastBattle-Day28.rbxl` or `BlockBlastBattle-Day29.rbxl`.
- Replaced the Day29 multi-zone spread with a focused Day30 central hub checkpoint in `src/server/world/HubBuilder.luau`.
- Added native Roblox Terrain generation for the central island mass so the hub has an irregular floating-land silhouette, rock underside, cliff layering, and grass/ground transitions instead of a visible rectangular base.
- Added a hidden safe walk surface inside the hub island to keep spawn and traversal reliable while terrain provides the visible landform.
- Rebuilt the central plaza as layered circular stone/marble flooring with radial mosaic stones, benches, flowers, trees, lamps, and two controlled waterfalls.
- Rebuilt the Brick Core as a stronger landmark with a two-stage pedestal, six marble/stone frame pillars, a metal crown, clustered colored core blocks, a controlled vertical beam, light, and sparse particles.
- Reduced Day29 clutter by removing unused rainbow trail, balloon, block statue, and shop-stall helper functions.
- Collapsed the side-island work into two polished route starts only:
  - Battle route: blue/red path language, bridge, landing terrain, gate, preserved `BattleQueuePad`, queue prompt, status billboard, bunting, lamps, and versus sculpture.
  - Story route: purple/gold path language, bridge, landing terrain, preserved `StoryQueuePad`, queue prompt, status billboard, ruin arches, floating fragments, tree, rocks, and lamps.
- Added a Studio-only F8 custom-HUD inspection toggle in `src/client/ui/BlockBlastClient.client.luau`. This is gated by `RunService:IsStudio()` and is not a normal production player control.
- Built `BlockBlastBattle-Day30.rbxl`.

### Day29 Elements Replaced

- Replaced the visible flat main island plate with source-generated terrain blobs and hidden gameplay support.
- Removed the weak full spread of Shop/Cosmetics, Guide/Settings, and Leaderboard side islands from this checkpoint so the visual budget can focus on a single approved central hub.
- Replaced the simple glowing cube-style core with a framed Brick Core landmark.
- Retained core gameplay contracts temporarily: `HubSpawn`, `BattleQueuePad`, `StoryQueuePad`, queue prompts, and recovery behavior.

### Asset Workflow

- No Creator Store or third-party assets were imported.
- No external asset IDs were used.
- No imported scripts, LocalScripts, ModuleScripts, loaders, untrusted requires, or asset hierarchies were added.
- Day30 uses reproducible Rojo source plus native Roblox Terrain generation; primitive Parts are limited to collision safety, plaza architecture, pads, gates, bridges, and readable gameplay surfaces.

### Current State

- Validation passes locally.
- Studio visual approval is still not complete because Codex could not capture reliable Play-mode screenshots from Roblox Studio in this session.
- `BlockBlastBattle-Day30.rbxl` should be opened locally for inspection.
- Press F8 in Studio Play mode to hide/show the custom HUD while reviewing the map.

### Required Manual Screenshots

Please capture these from `BlockBlastBattle-Day30.rbxl`:

1. Normal spawn view.
2. Plaza facing the Brick Core.
3. Three-quarter aerial view.

### Known Risks

- Terrain generation is runtime-authored by `HubBuilder`; visual quality must be verified in Studio because Rojo build validation cannot prove camera composition.
- Hidden safe walk surfaces are intentionally used for reliability; they should remain invisible but need Studio confirmation.
- The UI remains visually rejected from the screenshot and still needs its own later checkpoint. Day30 intentionally did not redesign it beyond the Studio-only F8 inspection toggle.

### Validation

- `.\tools\stylua.exe src` passed.
- `.\tools\selene.exe src` passed with `0 errors`, `0 warnings`, `0 parse errors`.
- `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-Day30.rbxl` passed.
- `git diff --check` passed with line-ending warnings only.

### Next Priority

- Review Day30 visually from the three required Studio screenshots and tune the central hub scale/composition before building remaining destination islands.

## Day29 Source Map Rescue - 2026-08-09

### Completed

- Identified the most likely manually edited Studio file as `BlockBlastBattle-Day28.rbxl` because it was modified after the clean Day28 checkpoint and grew from the clean build size to `246157` bytes.
- Backed up that file to `backups/BlockBlastBattle-Day28-manual-studio-backup-2026-08-09.rbxl` before replacing or rebuilding anything.
- Preserved the Day28 UI work; no Day28 HUD, shop UI, inventory UI, remotes, economy, product IDs, DataStores, or gameplay systems were redesigned.
- Reworked the runtime-generated hub in `src/server/world/HubBuilder.luau` toward a cohesive `Colorful floating puzzle kingdom` direction.
- Added reusable source prefabs/helpers for:
  - named zone folders
  - path slabs
  - low-poly rock clusters
  - lamps
  - banners
  - ruin arches
  - shop stalls
  - puzzle monuments
  - battle gateways
- Reorganized the generated hub into named zones:
  - `BattleIslandZone`
  - `StoryIslandZone`
  - `ShopCosmeticsDistrict`
  - `GuideSettingsZone`
  - `LeaderboardVistaZone`
- Upgraded the central island with clearer route paths, directional banners, route lamps, and a more deliberate welcome puzzle landmark around the existing Block Core.
- Redesigned the Battle island with a blue/red competitive gate, clearer BattleQueuePad framing, blue/red lane treatment, banners, and versus puzzle sculpture while preserving the `BattleQueuePad` name and queue prompt.
- Redesigned the Story island with purple/gold ruins, arch structures, floating fragments, lamps, and the preserved `StoryQueuePad` prompt.
- Added a distinct Shop/Cosmetics district with purple/gold boutique stalls, display pedestals, runway path, balloons, and signage without creating fake functional purchases.
- Added a quieter Guide/Settings practice island and a leaderboard vista.
- Added distant floating kingdom silhouettes to the background scenery for depth, with collisions disabled.
- Built `BlockBlastBattle-Day29.rbxl` without overwriting Day28.

### Manual Import Audit

- The likely manually edited file was backed up, but Codex could not inspect binary `.rbxl` DataModel contents in this session without Roblox Studio/MCP control or a trusted `.rbxl` parser.
- No external Creator Store assets or asset IDs were imported during this checkpoint.
- No third-party scripts were added to source.
- The final Day29 map source of truth is `HubBuilder.luau`, so the redesigned hub will survive future Rojo builds.

### Performance Notes

- Runtime hub generation remains mostly native Roblox Parts, but the new helpers use varied cylinders, balls, slabs, arches, stalls, lamps, banners, and grouped prefabs instead of unrelated manually imported assets.
- Decorative foliage, rocks, lamps, banners, distant silhouettes, floating fragments, and display props are non-collidable.
- Gameplay-critical platforms, bridge decks, spawn, queue pads, arena decks, and recovery platform remain collidable.
- Static Rojo place file counts do not include the runtime-generated hub; the generated map expands when `HubBuilder.build()` runs in Studio.
- Source-generation deltas from Day28 to Day29:
  - `makePart` call sites: `49` to `65`
  - `makeNeon` call sites: `11` to `13`
  - `addParticles` call sites: `9` to `7`
  - `addLight` call sites: `5` to `6`

### Current State

- New local build: `BlockBlastBattle-Day29.rbxl`
- Temporary XML count build: `BlockBlastBattle-Day29-count.rbxlx`
- Backup of likely manual Studio edit: `backups/BlockBlastBattle-Day28-manual-studio-backup-2026-08-09.rbxl`
- Visual verification remains manual because Codex still cannot reliably capture/control Studio Play mode in this session.

### Next Priority

Open `BlockBlastBattle-Day29.rbxl` in Roblox Studio, press Play, and verify spawn, central plaza sightlines, all bridges, Battle queue, Story prompt, Shop/Cosmetics area, active battle entry/return, and low/mobile graphics readability from the player camera.

## Day28 Selected UI Concept Implementation - 2026-08-02

### Completed

- Implemented the selected concept direction in the actual Roblox UI instead of producing another concept sheet.
- Replaced the immediate hub HUD with an Option B-inspired simulator/arcade layout:
  - top resource bar for Level, XP, Coins, Wins, and Story Stars using live `leaderstats`
  - compact left utility navigation for Quests and Modes
  - right-side Play, Shop, Inventory, and Settings actions
  - state-aware Play button for `PLAY`, `LEAVE`, and `FULL`
  - contextual queue/match banner with valid leave-queue control
- Disabled the conflicting legacy Home panel visibility path so the player no longer sees duplicate hub interfaces.
- Restyled the shared menu shell with dark navy structure, bright blue strokes, red close button, and arcade spacing.
- Restyled the Shop panel toward the selected Option B shop direction:
  - purple/navy outer window
  - left category rail
  - stronger `SHOP` title and red close button
  - brighter item cards while preserving existing server-authoritative purchase requests and item states
- Restyled Inventory/Cosmetics toward the selected Option C direction:
  - dark outer shell with left category rail
  - lighter item cards
  - clear equipped, unlocked, and locked visual states
- Restyled the active battle window and dock with a compact dark-tech treatment while preserving board, hand, rotate/reroll, return, and replay behavior.
- Marked previously generated UI PNG packs as rejected-only references; no icon pack is approved for upload.
- Built `BlockBlastBattle-Day28.rbxl`.

### Files Modified

- `src/client/ui/HUDController.luau`
- `src/client/ui/MenuController.luau`
- `src/client/ui/ShopPanel.luau`
- `src/client/ui/CosmeticPanel.luau`
- `src/client/ui/BlockBlastClient.client.luau`
- `src/client/ui/UITheme.luau`
- `src/client/ui/UIAssets.luau`
- `docs/UI_ICON_UPLOAD_MANIFEST.md`
- `DEVELOPMENT.md`
- `docs/PROJECT_TRACKER.md`

### Current State

- The next local build to open is `BlockBlastBattle-Day28.rbxl`.
- The selected UI direction is now implemented with native Roblox GUI objects, not uploaded image assets.
- Custom icons are still temporary native shape silhouettes; no rejected PNGs are wired into the game.
- Roblox Studio was launched with the Day28 file, but Codex does not currently have reliable Studio screenshot capture/control in this session, so Play-mode visual approval still needs manual screenshots.

### Next Priority

Open `BlockBlastBattle-Day28.rbxl`, press Play, and capture desktop/mobile screenshots for hub, shop, inventory, queue state, and active battle. Fix any overlap or spacing issues found in those screenshots before adding more visual systems.

## Day27 Blocky UI Direction - 2026-08-02

### Completed

- Generated a blocky competitive / BedWars-inspired icon language draft that was later rejected.
- Generated a separate chosen icon pack under `assets/ui/icons-blocky-bedwars`.
- Added `assets/ui/mockups/blocky-bedwars-icon-pack-preview.png` as a preview sheet.
- Added `scripts/generate-blocky-ui-icons.ps1` so the chosen pack can be regenerated.
- The later Day28 correction marks this pack as rejected-only and not approved for upload.

### Current State

- No generated icon pack is approved for upload.
- The game uses native UI components and temporary consistent shape silhouettes instead of relying on uploaded image IDs.

### Next Priority

Approve the Day28 native UI direction from Play-mode screenshots before producing any final icon assets.

## Day26 Free HUD Icon Pack - 2026-08-02

### Completed

- Generated a free project-owned HUD icon pack for Play, Shop, Quests, Settings, Coins, Wins, and Story Stars.
- Added `assets/ui/icons/*.png` source upload files and `assets/ui/mockups/hud-icon-upload-pack-preview.png`.
- Added `scripts/generate-ui-icons.ps1` so the icon pack can be regenerated without paid assets.
- Added `docs/UI_ICON_UPLOAD_MANIFEST.md` mapping every PNG to its `UIAssets.luau` key.
- Rebuilt `BlockBlastBattle-Day26.rbxl`.

### Current State

- The PNG files are ready to upload, but the Roblox UI cannot display them until Roblox image asset IDs are pasted into `UIAssets.luau`.
- Day26 still safely falls back to text badges if the IDs are blank.

### Next Priority

Upload the seven PNGs in `assets/ui/icons`, paste the returned IDs into `UIAssets.luau`, then rebuild the next Day file so the in-game HUD uses real images.

## Day25 Free UI Asset Pipeline - 2026-08-02

### Completed

- Chose the free UI improvement path instead of purchasing a UI pack.
- Added `src/client/ui/UIAssets.luau` as the centralized home for uploaded Roblox UI image IDs.
- Updated `HUDController.luau` so Play, Shop, Quests, Settings, Coins, Wins, and Story Stars can automatically use `ImageLabel` icons once IDs are filled in.
- Preserved safe text-badge fallbacks so the HUD still works before asset upload.
- Added `docs/FREE_UI_ASSET_WORKFLOW.md` with the Figma/RoImport/free Creator Store quarantine workflow.

### Current State

- No paid assets are required for the next UI pass.
- The game is ready to accept free/generated/uploaded icon assets without scattering IDs across the codebase.
- The actual icon PNGs still need to be created or selected and uploaded through Roblox Creator Dashboard.

### Next Priority

1. Create the seven icon PNGs for Play, Shop, Quests, Settings, Coins, Wins, and Story Stars.
2. Upload them to Roblox and paste the resulting IDs into `UIAssets.luau`.
3. Replace more of the shop/menu visuals with imported Figma/RoImport components after the HUD icon pass is working.

## Day24 Option A Polish Follow-Up - 2026-08-02

### Completed

- Tightened the selected Option A HUD implementation after playtest feedback that Day23 still looked too rough.
- Replaced single-line text-button visuals with layered native Roblox UI: play badge, main play label, compact button badges, and stat badges.
- Added simulator-style badges to the coin, wins, and Story Stars bars so the HUD reads more like a polished Roblox experience.
- Preserved server-authoritative behavior; the UI changes do not grant rewards, currency, ownership, or queue state from the client.
- Built `BlockBlastBattle-Day24.rbxl`.

### Image Asset Decision

- The concept image cannot be pasted in as the full working interface because a screenshot would not be interactive, responsive, accessible, or state-aware.
- Roblox UI image art must use uploaded image asset IDs such as `rbxassetid://123`.
- Next icon pass should generate project-owned PNG icons, upload them through Creator Dashboard, record the IDs in a centralized module, then swap the temporary native text badges for `ImageLabel` icons.

## Day23 Option A HUD Checkpoint - 2026-08-02

### Completed

- Reworked the default hub HUD toward the selected Option A concept.
- Replaced the busy right-side action rail with a bottom-center primary action cluster.
- Made `PLAY` the clear first action, with compact `SHOP`, `QUESTS`, and `SETTINGS` buttons underneath.
- Moved the player profile, level, XP bar, coins, wins, and Story Stars back to a compact upper-left stat stack.
- Hid the persistent objective card on spawn so the first screen feels cleaner for new players.
- Made the Play button state-aware: it now changes to `LEAVE QUEUE` while queued and `ARENAS FULL` when no arenas are open.
- Renamed the old Rewards quick panel copy to `Quests` so the visible button matches player expectations while the full quest board is still planned.
- Built `BlockBlastBattle-Day23.rbxl`.

### Files Modified

- `src/client/ui/HUDController.luau`
- `src/client/ui/BlockBlastClient.client.luau`
- `DEVELOPMENT.md`
- `docs/PROJECT_TRACKER.md`

### Current State

- The hub HUD now follows the cleaner Option A direction: fewer always-visible buttons, stronger visual hierarchy, and a much more obvious play action.
- The existing Home panel, Story panel, Shop panel, and gameplay board remain intact.
- The `Quests` button currently opens an honest informational placeholder; it does not fake a completed quest system.
- Studio visual confirmation is still required to judge exact spacing against Roblox chat/topbar and mobile controls.

### Next Priority

1. Playtest `BlockBlastBattle-Day23.rbxl` in Studio and screenshot the spawn HUD at desktop and phone landscape sizes.
2. Replace text symbols on the HUD buttons with project-owned image icons after the layout is approved.
3. Apply the same Option A visual language to the remaining Home panel or retire parts of that older panel once the new hub HUD covers the same jobs.

## Completed Work

- 2026-07-29: Set up Rojo-based Roblox project structure for VS Code development.
- 2026-07-29: Added generated hub, battle queue pad, story placeholder pad, and spawn handling.
- 2026-07-29: Built draggable/resizable battle UI with piece previews, rainbow pieces, placement preview, and leaderboard display.
- 2026-07-29: Added first battle arena map with two player decks, arena spawns, bridge, glow pillars, walls, and scoreboard.
- 2026-07-29: Added placement pop, clear flash, invalid-placement shake, queue pulse, battle banners, hub close button, and side logo reopen behavior.
- 2026-07-29: Added round timer, solo queue countdown, and basic `Wins` leaderstat.
- 2026-07-29: Hardened placement remotes with type/range checks and cooldown throttling.
- 2026-07-29: Replaced one-off best-score saving with versioned profile data for best score and wins.
- 2026-07-29: Added hub accessibility controls for reduced motion and Auto/Large/Compact UI size.
- 2026-07-29: Added battle rewards for coins, XP, levels, winner bonus payouts, and progression display.
- 2026-07-29: Replaced story-mode placeholder with a starter solo training run using the Block Blast board.
- 2026-07-29: Added Leave Queue flow so queued players can cancel matchmaking from the hub UI.
- 2026-07-29: Added persistent settings for theme, reduced motion, and UI size through versioned profile saves.
- 2026-07-29: Added first-time onboarding panel with basic placement instructions and a saved completion flag.
- 2026-07-29: Added loading splash with fade-out and fallback dismissal for smoother first join.
- 2026-07-29: Added persistent piece skin customization with Rainbow, Neon, Pastel, and Ice generation styles.
- 2026-07-29: Added persistent sound setting and client-side cues for UI clicks, queueing, placement, blocked moves, clears, and results.
- 2026-07-29: Added isolated match sessions with per-session timers, leaderboards, finish state, and three physical arena slots.
- 2026-07-29: Added hub matchmaking status for open arenas, active matches, queue size, and full-arena feedback.
- 2026-07-29: Added visible match/arena diagnostics and a multiplayer stress-test plan for Studio local server validation.
- 2026-07-29: Added a Studio-only diagnostics overlay with current mode, arena, match, queue, and active session summaries.
- 2026-07-29: Added persistent board skin customization with Auto, Midnight, Sugar, Garden, and Contrast skins.
- 2026-07-29: Hardened queue/settings remotes with queue action cooldowns, explicit mode handling, and debounced settings saves.
- 2026-07-29: Expanded Story Training into rotating server-authored missions with visible objectives, completion rewards, and persistent Story Stars.
- 2026-07-29: Added compact touch layout for the battle window with stacked board/piece controls and safer small-screen scaling.
- 2026-07-29: Added progression-gated cosmetic unlock requirements for piece and board skins with server-side enforcement and hub hints.
- 2026-07-29: Added hub story chapter preview showing the next mission title, objective, and Story Stars before starting Story Training.
- 2026-07-29: Hardened profile persistence with bounded save retries, DataStore load/save warnings, shutdown save sweep, and Studio save-failure diagnostics.
- 2026-07-29: Added server playtest analytics counters for battle/story sessions, queue joins/leaves, placements, clears, invalid placements, and story completions.
- 2026-07-29: Prevented early-leave reward farming by treating active run exits as forfeits with no payout and tracking forfeits in diagnostics.
- 2026-07-29: Added suspicious placement-request diagnostics for malformed, stale-session, and cooldown-throttled placement remotes.
- 2026-07-29: Added visual cosmetic swatches to hub piece and board skin controls for quicker customization browsing.
- 2026-07-29: Preserved each player's personal reward or forfeit summary when returning from a run to the hub.
- 2026-07-29: Added a structured post-run results panel with score, lines, rewards, best-score progress, close, and quick battle queue actions.
- 2026-07-29: Extracted the post-run results UI into a dedicated client module as the first step toward splitting the large client UI script.
- 2026-07-29: Added server-authored next-cosmetic-unlock hints to the post-run results panel.
- 2026-07-29: Added a cosmetic closet panel with piece/board preview grids, equipped states, locked requirements, and direct equip actions.
- 2026-07-29: Added story chapter intro, success, and failure copy to mission starts, in-run objectives, and post-run results.
- 2026-07-29: Replaced delayed client-side replay sequencing with a server-authoritative `PlayAgain` queue action that only requeues from hub or finished runs.
- 2026-07-29: Extracted client sound cue creation, volume, mute, and playback into a dedicated `SoundController` module.
- 2026-07-29: Added battle sudden death with server-owned pressure rows, warning banners, red timer state, and diagnostics counters.
- 2026-07-29: Added a Story Missions panel with recent chapter browsing, replay access for completed chapters, locked upcoming chapter previews, and server-validated selected chapter starts.
- 2026-07-29: Hardened Story Stars so replayed chapters can earn base rewards but cannot farm additional progression stars.
- 2026-07-29: Hardened profile persistence by clamping loaded/saved leaderstat values, rejecting invalid numeric profile data, and surfacing sanitized-field counts in Studio diagnostics.
- 2026-08-01: Hardened server settings sanitization so numeric settings reject NaN/infinite values before clamp/floor handling.
- 2026-08-01: Mirrored finite-number settings guards on the client before applying theme, UI scale, and sound volume updates.
- 2026-08-01: Built `BlockBlastBattle-Day4.rbxl` after `BlockBlastBattle-Day3.rbxl` was locked by an open Studio session.
- 2026-08-01: Added server-authoritative combo streaks, combo score bonuses, live combo banners, best-combo tracking, and match duration/best-combo result stats.
- 2026-08-01: Added a server-authoritative first-win daily bonus for battle victories or next-chapter story completions, persisted claim dates, hub reminder text, and result-panel bonus feedback.
- 2026-08-01: Added a replayable hub Guide button that reopens the tutorial without resetting saved tutorial completion.
- 2026-08-01: Added a complete first shop vertical slice with Featured, Passes, Cosmetics, and Currency categories, responsive reusable product cards, server-fed item state, loading/owned/equipped/locked/unavailable/error feedback, touch-sized controls, and gamepad focus entry.
- 2026-08-01: Added secure monetization scaffolding with centralized placeholder game pass/developer product IDs, server-validated prompt requests, prompt locks, cached game pass ownership refreshes, post-purchase game pass refresh, and server-only developer product receipt fulfillment.
- 2026-08-01: Hardened developer-product receipts so fulfilled purchase IDs persist inside the player profile in the same durable update that applies currency, avoiding duplicate grants across receipt retries and server restarts.
- 2026-08-01: Added low-volume shop analytics counters for snapshot requests, prompt requests, rejected prompts, completed/cancelled prompts, ownership refreshes, and developer product receipt outcomes.
- 2026-08-01: Documented Creator Dashboard monetization setup in `docs/MONETIZATION_SETUP.md` and kept placeholder IDs at `0` until real Roblox assets exist.
- 2026-08-01: Evaluated React Luau for the shop slice and deferred it because the project has no React/Wally dependencies installed; the production slice instead uses a reusable, state-driven Luau panel architecture compatible with the existing Rojo app.
- 2026-08-01: Built the next place artifact as `BlockBlastBattle-Day6.rbxl`.
- 2026-08-01: Modernized the home hub layout with a wider first-screen panel, larger Battle/Story touch targets, dedicated Shop & Closet action, less cramped settings controls, theme-aware shop entry styling, and gamepad focus when the home panel opens.
- 2026-08-01: Added a centralized server-authoritative cosmetic catalog for piece skins, board skins, line-clear effects, and player titles.
- 2026-08-01: Added persistent cosmetic inventory schema `profile.cosmetics` with owned IDs, equipped IDs by category, default migration, and safe fallback for invalid saved entries.
- 2026-08-01: Connected the shop Cosmetics tab to server-owned catalog snapshots with coin purchase, equip, pass-required, locked, unavailable, preview, owned, and equipped states.
- 2026-08-01: Applied equipped cosmetics to gameplay for piece colors, board theme, line-clear feedback, and in-run player title presentation.
- 2026-08-01: Added `docs/STUDIO_TEST_CHECKLIST.md` covering migration, shop, Marketplace, mobile/gamepad, reduced-motion, and two-player cosmetic validation.
- 2026-08-01: Added centralized low-volume shop analytics for shop opens, tab selection, cosmetic previews, cosmetic purchase attempts/success/failure, cosmetic equips, and gamepass prompt openings.
- 2026-08-01: Added shared `UITheme` design tokens/helpers for panels, cards, text, buttons, and reduced-motion-aware button feedback.
- 2026-08-01: Modernized the shop, results panel, hub shell, battle window, minimized battle dock, tutorial panel, and toast banner with consistent rounded surfaces, strokes, gradients, and cross-input `Activated` controls.
- 2026-08-01: Brought Story Missions and Cosmetic Closet panels onto the shared UI theme with state-aware card strokes and cross-input activation.
- 2026-08-01: Added default gamepad focus and directional focus paths to results, story missions, and cosmetic closet panels.
- 2026-08-01: Extracted the modernized home hub interface into `src/client/ui/HomePanel.luau`, moving home-owned instances, activation connections, focus paths, responsive scale, show tween, cosmetic swatches, matchmaking labels, and queued pulse ownership out of the main client script.
- 2026-08-01: Added `docs/STUDIO_MCP_VALIDATION.md` with official Roblox Studio MCP Quick Connect steps and an unexecuted Studio test matrix for Day9.
- 2026-08-01: Built the next place artifact as `BlockBlastBattle-Day8.rbxl`.
- 2026-08-01: Rebuilt the generated hub and arenas into a floating competitive puzzle world with a Block Core landmark, Battle/Story portals, block-market area, richer battle arenas, distant scenery, lighting, atmosphere, and restrained decorative animation/VFX.
- 2026-08-01: Added `docs/ENVIRONMENT_VISUAL_AUDIT.md` and `docs/ASSET_AUDIT.md` documenting the visual problems found, implementation choices, imported-asset status, safety checks, and remaining Studio testing needs.
- 2026-08-01: Built the next place artifact as `BlockBlastBattle-Day10.rbxl`.
- 2026-08-01: Replaced the dark tech-style hub with a brighter front-page-style floating island lobby featuring a circular spawn plaza, clouds, waterfalls, bridges, trees, flowers, themed islands, portals, VIP/secret/training/leaderboard areas, and a glowing central Block Core.
- 2026-08-01: Added Day14 hub/play-loop hardening with server-updated Battle/Story world signs, queue pad visual reactions, stale queue pruning, duplicate spawn-connection cleanup, reset/death queue/session handling, non-blocking lobby decorations, and client-side reduced-motion scaling for hub particles/lights/post-processing.
- 2026-08-01: Added Day15 local player HUD polish with left-side player/progression/objective cards, right-side action rail, reusable side menu panel, stacked notifications, bright floating-island HUD theme tokens, responsive collapse behavior, and Reduced Motion-aware menu/notification feedback.

## Current Priorities

- Extract the modernized home/hub interface into a cohesive reusable module instead of continuing to grow `BlockBlastClient.client.luau`.
- Execute Studio multiplayer stress tests using the diagnostics overlay and fix issues found.
- Extract the modernized home/hub interface into a cohesive reusable module instead of continuing to grow `BlockBlastClient.client.luau`.
- Continue anti-exploit hardening around server-authoritative economy events and abnormal session lifecycle edge cases.
- Polish core game feel around line clears, incoming pressure, victory/defeat, and reward reveals.
- Add quest or challenge presentation that builds on the first-win daily bonus without creating exploitable reward spam.
- Add richer original audio assets and mix testing.
- Expand Story Training with more mission types, longer chapter arcs, and better hub-world story signposting.
- Validate compact touch layout in Roblox Studio device emulation.

## Known Issues

- `BlockBlastBattle.rbxl` may be locked if Roblox Studio has it open; build to a day-specific place file instead.
- Rojo plugin connection still needs a live Roblox Studio playtest.
- Two-player battle flow needs Roblox Studio local server testing.
- First-time onboarding and compact battle layout need Studio validation across desktop and mobile screen sizes.
- Current battle board is UI-only; future versions should consider an optional 3D board representation in the arena.
- Monetization IDs are intentionally `0`; real purchase prompt testing is blocked until Creator Dashboard game passes and developer products exist.
- Developer product receipt persistence now uses profile `fulfilledPurchaseIds`; it still needs live DataStore failure testing before any real currency products are enabled.
- Roblox Studio MCP still is not connected to Codex for direct Studio control. The local Studio MCP executable initializes, but tool listing/Studio control did not become available, so Day10 visual testing remains manual.

## Technical Debt

- `BlockBlastClient.client.luau` is still large; `ResultPanel.luau`, `CosmeticPanel.luau`, `SoundController.luau`, `StoryPanel.luau`, and `ShopPanel.luau` are the first extractions, and battle board, hub panel, and settings controls should follow.
- Profile save data covers best score, wins, coins, XP, level, Story Stars, first-win daily claim date, core settings, piece skin, and board skin; numeric profile and settings values are sanitized on both server and client, while broader cosmetic inventory still needs persistence.
- Shop product definitions and cosmetic ownership are centralized; cosmetic presets still need a real UI and server validation flow.
- Extra Preset Slots Pass remains marked unavailable while its real preset UI/server save flow is unfinished.
- Effects are client-side only and need particle polish plus final audio asset replacement.
- Match sessions now support multiple active arenas with hub availability UI, analytics, exploit diagnostics, and Studio diagnostics; production still needs Studio stress execution and richer arena lifecycle tooling.
- The Day10 world is still generated from one large `HubBuilder.luau` module; future map iterations may benefit from splitting hub landmarks, scenery, lighting, and arena generation into focused builder modules.

## Release Readiness

- Status: Prototype.
- Not ready for public release until multiplayer, save retries, mobile UI, monetization IDs/purchase flows, moderation/anti-exploit, onboarding, audio, and retention loops are tested in Studio.
- Day10 improves the first visual read of the world, but it still requires in-Studio camera, collision, mobile readability, and performance validation before being treated as release art.
- Day14 preserves the Day13 lobby design and adds repository-side safeguards, but full Studio validation is still required for bridge traversal, prompt input on mobile/controller, two-player lifecycle, and actual device performance.

## Session Update - 2026-08-01 Day14 Play-Loop Hardening

### Completed

- Added server-updated world status billboards above Battle and Story destinations so players can read queue count, solo countdown, arena-full state, and story availability from the 3D hub.
- Added queue pad visual reaction by tinting `BattleQueuePad` while the queue is active.
- Added stale queue pruning before hub-state sends and match-start checks, preventing disconnected or non-hub players from lingering in queue state.
- Hardened `startBattle` so it filters eligible players immediately before arena allocation and does not start sessions for invalid, disconnected, or stale queued players.
- Removed duplicate hub spawn-safety `CharacterAdded` handling from player initialization.
- Added character death/reset handling: queued hub players leave queue, and active Battle/Story players safely forfeit/return through the existing `leaveBattle` flow.
- Disconnected per-player character/humanoid connections on player removal.
- Made decorative benches, tree trunks, and bridge lantern posts non-colliding to reduce movement snags in the lobby.
- Added local reduced-motion world-quality scaling in `BlockBlastClient.client.luau` that lowers hub particle rates, point-light brightness, bloom, sun rays, and depth of field for lower-end/mobile users without changing server state.
- Built `BlockBlastBattle-Day14.rbxl`.

### Remaining Studio-Only Checks

- Verify `HubSpawn` orientation, camera angle, and player clearance in Studio Play.
- Walk every bridge and island entrance to confirm no collision gaps or snag points remain.
- Confirm `BattleQueuePad` and `StoryQueuePad` prompts work with keyboard, controller, and mobile touch.
- Run two-player local server tests for queue join/leave during countdown, disconnects, resets, ties, and match cleanup.
- Compare normal vs Reduced Motion in device emulation and check whether additional particles/lights should be reduced.

### Unresolved Risks

- Studio MCP is still unavailable from Codex, so Output inspection and device/player simulation must be done manually in Roblox Studio.
- The lobby is still generated from one large world-builder module; future maintenance would benefit from splitting signage, islands, arenas, and lighting into smaller files.

## Session Update - 2026-08-01 Day15 Player HUD Polish

### Completed

- Added `src/client/ui/HUDController.luau` as a local-only PlayerGui HUD controller.
- Added a left-side HUD stack with compact cards for avatar/display name, Level/XP, Coins, Wins, Story Stars, current mode, and current objective/status.
- Added a right-side action rail with Play, Modes, Inventory, Shop, Rewards, Quests, Codes, and Settings.
- Connected functional right-side buttons to existing safe client flows:
  - Play queues/leaves battle or reopens the active battle board.
  - Modes opens the existing Story Missions panel.
  - Inventory opens the existing Cosmetic Closet panel.
  - Shop opens the existing Shop panel.
  - Rewards and Settings open local informational panels.
- Labeled Quests and Codes as coming soon instead of presenting them as functional systems.
- Added `src/client/ui/MenuController.luau`, a reusable local side-panel system with one-open-menu behavior, dim background, title bar, close button, Escape/controller-back close, and responsive sizing.
- Added `src/client/ui/NotificationController.luau`, a stacked notification system with success/warning/error/reward/info styling, duplicate suppression, auto-dismiss, and Reduced Motion behavior.
- Updated `src/client/ui/UITheme.luau` with bright HUD/floating-island theme tokens.
- Wired HUD state updates to existing hub state, battle/story state, leaderstats, settings, and Reduced Motion paths without adding client-authoritative rewards or currencies.
- Built `BlockBlastBattle-Day15.rbxl`.

### Responsive Behavior

- Desktop keeps a wider right-side button rail with icon plus text labels.
- Tablet and narrow laptop widths collapse the right rail to icon-first buttons.
- Phone-sized layouts reduce left HUD width, hide the secondary stats card, keep the objective card compact, and preserve the bottom screen area for Roblox movement controls.
- Top HUD remains a compact contextual zone/status pill instead of a permanent full-width bar.

### Placeholder Versus Functional Buttons

- Functional: Play, Modes, Inventory, Shop, Rewards, Settings.
- Explicit placeholder: Quests, Codes.
- Rewards is informational only; actual reward grants remain server-owned and shown through result panels.
- Settings is informational for now; full setting controls remain in the existing Home panel.

### Reduced Motion Integration

- Button feedback already respects Reduced Motion through shared `UITheme` feedback.
- Notifications skip slide animation when Reduced Motion is enabled.
- Menu panels skip slide animation when Reduced Motion is enabled.
- Existing world-quality Reduced Motion behavior from Day14 remains intact.

### Remaining Studio-Only Checks

- Test desktop 1920x1080 and laptop 1366x768 for no overlap with chat, top bar, or existing home panel.
- Test tablet and phone landscape for right-rail collapse, left-card readability, and mobile movement-control clearance.
- Confirm Escape and controller B close the new side menu.
- Confirm reset/respawn does not duplicate HUD, notifications, or event connections.
- Confirm new HUD does not obscure Battle board controls during active matches.

### Recommended Next UI Improvement

- Move the remaining centered Home panel controls into the new `MenuController` pattern so Play/Modes/Inventory/Shop/Settings feel like one consistent UI system.

## Session Update - 2026-08-01 Day10 Environment Pass

### Completed

- Replaced the plain generated hub in `src/server/world/HubBuilder.luau` with a substantial original Parts-only floating puzzle world.
- Added a dramatic central Block Core, glowing path guides, a dominant Battle portal, distinct Story portal, Shop/Closet block-market area, Guide corner, leaderboard monolith, distant floating islands, and puzzle-block silhouettes.
- Expanded the three battle arenas with stronger staging, deck frames, energy lanes, attack channels, scoreboard crowns, spectator block stacks, conveyor tiles, rails, glow pillars, and clean return pads.
- Added controlled lighting and atmosphere through Future lighting, named Atmosphere/Bloom/ColorCorrection effects, local PointLights, low-rate ParticleEmitters, and slow decorative TweenService rotation loops.
- Preserved gameplay-critical names, attributes, prompt behavior, spawn parts, arena return values, collision on player surfaces, and server-owned gameplay/networking/security behavior.
- Added `docs/ENVIRONMENT_VISUAL_AUDIT.md` and `docs/ASSET_AUDIT.md`.

### Current State

- The world is much more visually readable from the spawn path and has clear landmarks for Battle, Story, Shop/Closet, Guide, and arena destinations.
- No Creator Store models, third-party assets, imported scripts, meshes, textures, sounds, packages, or plugins were used.
- Roblox Studio MCP is still not controllable from this Codex session. The Studio MCP executable responded to `initialize`, but `tools/list` never exposed usable Studio tools, so no Studio playtest, Output inspection, screenshots, or device emulation was executed.
- The build artifact for this checkpoint is `BlockBlastBattle-Day10.rbxl`.

### Recommended Next Priorities

1. Manually test `BlockBlastBattle-Day10.rbxl` in Roblox Studio.
   This should happen first because camera framing, collision, Output errors, UI overlay readability, and mobile/gamepad behavior can only be trusted after a real Studio run.
2. Fix any Studio-discovered environment issues.
   The most likely risks are decorative collision, spawn sightline, portal prompt placement, lighting brightness, or arena readability from the player camera.
3. Split `HubBuilder.luau` into focused world modules.
   The generated world now has enough content that separating lighting, hub landmarks, scenery, and arena generation would make future art passes easier.
4. Continue the next player-facing visual slice.
   After the world is verified, the best follow-up is matching the results/rewards presentation and tutorial guide polish to the stronger hub identity.

### Technical Debt

- `HubBuilder.luau` is now large and should eventually be split into smaller world-generation modules.
- Decorative animation is server-authored. It is low-volume, but future heavier animation should move client-side or become static if performance testing shows cost.
- The world still uses simple primitives only; this is safe and performant, but future custom meshes could improve silhouettes after a proper asset safety review.

### Ideas

- Add subtle portal arrival effects when players enter Battle or Story.
- Add animated shop display pedestals that preview owned/equipped cosmetics.
- Add match-state arena lights that change during sudden death, victory, and defeat.
- Add a short camera fly-in or spawn orientation cue once Studio testing confirms comfort on mobile.

### Release Readiness

- Estimate: prototype moving toward alpha, roughly 42% of the way to a public Roblox release.
- Biggest remaining blockers: Studio MCP/manual Studio validation, multiplayer stress testing, real monetization IDs and purchase testing, mobile UI/gamepad validation, and production DataStore confidence.
- Biggest gameplay weakness: battle readability and pacing still need real two-player playtests.
- Biggest polish opportunity: connect the improved 3D hub identity with stronger transitions, audio, and reward reveals.
- Biggest technical risk: untested Studio behavior for generated decorative geometry, focus paths, and local-server match lifecycle.

## Session Update - 2026-08-01 Shop Slice

### Completed

- Built `src/client/ui/ShopPanel.luau`, a reusable state-driven shop panel with category tabs, product-card rendering, responsive scaling, touch-friendly activation buttons, and gamepad focus on open.
- Integrated the shop into `src/client/ui/BlockBlastClient.client.luau` through the existing hub cosmetics entry, while preserving the old closet as the equip destination for progression cosmetics.
- Added `src/shared/game/Config.luau` monetization definitions for VIP Pass, Deluxe Cosmetics Pass, Extra Preset Slots Pass, Supporter Pass, and three placeholder coin developer products.
- Added `BlockBlastRemotes.Shop` in `src/server/services/GameServer.server.luau` with validated actions, prompt throttling, prompt locks, placeholder rejection, cached ownership checks, post-purchase refresh, and server-only developer product receipt fulfillment.
- Added dormant server reward hooks for owned pass benefits. Because every marketplace ID is `0`, no player can currently receive paid benefits accidentally.
- Added shop analytics counters to the existing server diagnostics data model.
- Added `docs/MONETIZATION_SETUP.md` with the Creator Dashboard steps and ID replacement rules.
- Formatted with Stylua, linted with Selene, and built `BlockBlastBattle-Day6.rbxl`.

### Current State

- The shop is a visible playable UI slice, but real Roblox purchase prompts remain intentionally unavailable until dashboard IDs replace the `0` placeholders.
- React Luau was deferred. The project currently has empty Wally dependencies and no React mounting/runtime pattern, so introducing React during this monetization pass would have increased migration risk without improving this release checkpoint.
- The client never grants currency, cosmetics, XP, or ownership.
- The server owns entitlement checks, prompt approval, receipt fulfillment, and post-purchase refresh.

### Recommended Next Priorities

1. Extract and modernize the hub/home UI.
   This is now the weakest player-facing area and will reduce the oversized main client script.
2. Add a true cosmetic inventory/equip model.
   The shop can display owned/equipped/locked states, but cosmetics are still derived from progression instead of an inventory table that can handle pass entitlements later.
3. Run Roblox Studio purchase and multiplayer tests after real IDs exist.
   The code builds locally, but MarketplaceService and multiplayer edge cases need Studio validation.
4. Improve mobile/gamepad navigation across all modal panels.
   The shop has focus entry and touch-sized buttons, but the older panels should be brought up to the same standard.

### Technical Debt

- Developer product receipt handling has persistent and in-memory receipt tracking, but real product enablement still requires live retry/failure testing.
- The shop UI destroys/recreates low-volume cards on refresh. This is acceptable for the current item count but could be pooled if the catalog grows.
- The existing hub controls are still laid out manually in the main client script.

### Ideas

- Add a featured rotation timer once the shop has real cosmetic inventory.
- Add preview thumbnails for each cosmetic card.
- Add a non-monetized daily deals area using earnable coins only.
- Add a VIP/supporter nameplate in the hub after game pass IDs are active.

### Release Readiness

- Estimate: prototype advancing toward alpha, roughly 35% of the way to public Roblox release.
- Biggest remaining blockers: Studio multiplayer validation, real Creator Dashboard monetization assets, mobile testing, and a polished onboarding/home flow.
- Biggest gameplay weakness: the core battle loop still needs more tactile arena feedback and pacing tests.
- Biggest polish opportunity: a modern home screen that clearly routes players into Battle, Story, Shop, Closet, and Settings.
- Biggest technical risk: Marketplace receipt and entitlement behavior must be tested with real Roblox services before any paid products are enabled.

## Session Update - 2026-08-01 Home Slice

### Completed

- Expanded the hub panel into a clearer home screen in `src/client/ui/BlockBlastClient.client.luau`.
- Enlarged Battle and Story actions for mouse/touch use and moved secondary settings into a cleaner two-column layout.
- Made Shop & Closet a dedicated primary home action instead of hiding shop access behind cosmetic hint copy.
- Added gamepad focus to the Battle queue button when the home panel opens.
- Updated home scaling to use one `HUB_SIZE` constant so future extraction has a cleaner boundary.
- Rebuilt `BlockBlastBattle-Day6.rbxl` after the home UI changes.

### Current State

- Home is visibly cleaner and easier to scan, but its implementation still lives inside the oversized main client script.
- The next clean architectural step is to extract this home surface into a `HomePanel` module similar to `ShopPanel`, `StoryPanel`, and `CosmeticPanel`.
- Roblox Studio device emulation is still needed to confirm safe-area behavior on phones and tablets.

### Recommended Next Priorities

1. Extract `HomePanel.luau`.
   The layout is now stable enough to move without redesigning it at the same time.
2. Add a true cosmetic inventory/equip model.
   Shop and closet are connected, but progression-derived cosmetics need a future-proof ownership layer.
3. Studio-test mobile and gamepad flow.
   The code validates locally, but Roblox input behavior needs device validation.

## Session Update - 2026-08-01 Cosmetic Inventory Slice

### Completed

- Added centralized cosmetic catalog definitions in `src/shared/game/Config.luau`.
- Added `profile.cosmetics` persistence with `owned`, `equipped`, placeholder `presets`, and `activePreset` fields.
- Migrated old saved piece/board settings into equipped cosmetic IDs when valid.
- Added safe defaults for fresh players and invalid saved cosmetic recovery.
- Made the shop Cosmetics tab use server snapshots instead of client-derived progression state.
- Added server-validated `PurchaseCosmetic` and `EquipCosmetic` shop actions.
- Added coin purchases for `BOARD_SUGAR` and `CLEAR_RIPPLE` with rollback on save failure.
- Added preview callbacks that let the client inspect piece/board visuals without granting or saving ownership.
- Applied equipped piece, board, line-clear, and title cosmetics to gameplay presentation.
- Added `docs/STUDIO_TEST_CHECKLIST.md`.

### Current State

- Cosmetics are now server-authoritative for ownership and equip.
- Existing quick piece/board buttons are still present, but server settings sanitization now checks inventory ownership and progression through the same catalog rules.
- Presets are only schema placeholders. The Extra Preset Slots Pass is intentionally unavailable until a real preset UI and validation flow exists.
- Studio validation has not been performed in this run.

### Recommended Next Priorities

1. Extract `HomePanel.luau`.
   The home UI is still the largest unrelated responsibility inside the main client script.
2. Complete cosmetic presets.
   The profile schema has placeholders, but slots, save/select UI, and Extra Preset Slots validation are not done.
3. Add a richer selected-item details area to the shop.
   Cards now work, but a details pane would improve preview and purchase confidence.

## Session Update - 2026-08-01 Shop Analytics Slice

### Completed

- Added validated `Shop` remote analytics tracking for a fixed allowlist of low-volume event names.
- Added counters for shop opens, tab selections, cosmetic previews, cosmetic purchase attempts/success/failure, cosmetic equips, and gamepass prompt openings.
- Emitted analytics from `ShopPanel.luau` without logging hover activity, personal information, or sensitive purchase data.
- Kept analytics outside the shop action cooldown so tracking cannot throttle snapshot, purchase, or equip requests.

### Current State

- Analytics are still in-memory diagnostic counters exposed through the existing server analytics model.
- Production analytics export is not connected yet.

## Session Update - 2026-08-01 UI Foundation Slice

### Completed

- Added `src/client/ui/UITheme.luau` with reusable design tokens and helpers for panel/card/button/text styling.
- Applied the shared visual system to `ShopPanel.luau`, including polished product cards, category tabs, modal shell, and button feedback.
- Modernized `ResultPanel.luau` with clearer reward and summary cards, larger action targets, and shared styling.
- Applied consistent styling to the hub shell, tutorial panel, toast banner, active battle window, minimized battle dock, and major home/gameplay buttons in `BlockBlastClient.client.luau`.
- Converted the main UI and updated shop/results panels from mouse-only `MouseButton1Click` handlers to Roblox `Activated` handlers for better mouse, touch, keyboard, and gamepad support.
- Formatted with Stylua, linted with Selene, and built `BlockBlastBattle-Day8.rbxl`.

### Current State

- The main UI is visibly more coherent and keeps the existing shop, cosmetics, gameplay, persistence, and monetization behavior intact.
- `BlockBlastClient.client.luau` still owns too much UI construction, but the new theme module gives future extractions a shared styling foundation.
- Roblox Studio device-emulation testing has not been performed in this run.

### Recommended Next Priorities

1. Extract the hub/home UI into `HomePanel.luau`.
   The surface is now visually stable enough to move into a cohesive module.
2. Apply the shared theme to `CosmeticPanel.luau` and `StoryPanel.luau`.
   These are now the most visually inconsistent modal panels.
3. Add more explicit gamepad focus paths between hub, shop, story, cosmetics, and battle controls.
   `Activated` support is improved, but focus order still needs deliberate Studio validation.

## Session Update - 2026-08-01 Modal Consistency Slice

### Completed

- Updated `src/client/ui/CosmeticPanel.luau` to use the shared `UITheme` panel, text, button, and feedback helpers.
- Added state-aware cosmetic card strokes so equipped, unlocked, and locked cards read more clearly without changing unlock logic.
- Updated `src/client/ui/StoryPanel.luau` to use the shared modal shell, text styles, button feedback, and state-aware mission card strokes.
- Converted Story and Cosmetic panel actions from `MouseButton1Click` to `Activated` for broader input support.
- Formatted with Stylua, linted with Selene, and rebuilt `BlockBlastBattle-Day8.rbxl`.

### Current State

- All major player-facing modal panels now share one visual system.
- Gameplay, shop, story, cosmetics, persistence, and monetization behavior remain unchanged aside from UI activation compatibility.
- Studio device-emulation and live gamepad focus-order testing are still needed.

### Recommended Next Priorities

1. Extract `HomePanel.luau`.
   This is now the biggest architecture win because the visual language is centralized and the home surface is still embedded in the large client script.
2. Add deliberate focus ordering/default selections to every modal panel.
   Buttons activate across inputs now, but gamepad/keyboard navigation should feel intentional.

## Session Update - 2026-08-01 Modal Focus Slice

### Completed

- Added default gamepad focus to `ResultPanel.luau`, selecting the replay/queue action when the results panel opens.
- Added directional focus paths in `StoryPanel.luau` so controller navigation moves between close and mission cards predictably.
- Added directional focus paths in `CosmeticPanel.luau` so controller navigation moves across piece cards and down into board cards.
- Formatted with Stylua, linted with Selene, and rebuilt `BlockBlastBattle-Day8.rbxl`.

### Current State

- Modal panels now have clearer controller entry points and navigation paths, but this still needs Roblox Studio controller/device validation.
- No server-authoritative gameplay, shop, monetization, or persistence behavior was changed.

### Recommended Next Priorities

1. Extract `HomePanel.luau`.
   This remains the highest-value architecture task because the home UI is visually improved but still embedded in the oversized main client script.
2. Studio-test UI navigation on mobile and gamepad.
   Repository validation passes, but actual Roblox focus movement should be checked with real input.

## Session Update - 2026-08-02 Day22 Default Simulator HUD

### Completed

- Restyled the always-visible hub HUD instead of only the shop modal.
- Moved player stats to a bottom-left simulator-style stack.
- Reworked profile/level into a bright blue pill with avatar and yellow XP bar.
- Reworked Coins, Wins, and Story Stars into chunky colored bars.
- Hid the top-center context bar during normal hub exploration; it only appears for queue/gameplay context.
- Reworked the right action rail into larger chunky labeled simulator buttons.
- Built `BlockBlastBattle-Day22.rbxl`.

### Validation

- `stylua src` passed.
- `selene src` passed with 0 errors and 0 warnings.
- `rojo build default.project.json --output BlockBlastBattle-Day22.rbxl` passed.
- `git diff --check` reported only Windows CRLF notices.

## Session Update - 2026-08-02 Day21 Simulator Shop Redesign

### Completed

- Restyled `ShopPanel.luau` toward the supplied Bubble Gum Simulator shop reference.
- Added a dimmed world overlay behind the shop.
- Added low-cost radial light-ray frames behind the shop panel.
- Rebuilt the shop frame as a bright blue/white modal with a large outlined `Shop` title.
- Added a large red chunky close button.
- Moved category tabs to a vertical side rail.
- Rebuilt product cards as bright simulator-style tiles with icon bubbles, outlined item names, blue Gift buttons, and green purchase buttons.
- Kept purchase logic server-authoritative; the new Gift button is clearly non-granting and only shows a planned-feature message.
- Built `BlockBlastBattle-Day21.rbxl`.

### Validation

- `stylua src` passed.
- `selene src` passed with 0 errors and 0 warnings.
- `rojo build default.project.json --output BlockBlastBattle-Day21.rbxl` passed.
- `git diff --check` reported only Windows CRLF notices.

## Session Update - 2026-08-02 Day20 Reference HUD Cleanup

### Completed

- Stopped auto-opening the hub welcome card on spawn; players now open it intentionally from the hub button.
- Stopped auto-opening the tutorial card; Guide is now the explicit access point.
- Suppressed the redundant `Welcome to the hub` notification banner.
- Reworked the right-side hub action rail into compact circular color buttons inspired by simulator UI references.
- Removed always-visible Quests/Codes coming-soon buttons from the right rail to reduce clutter.
- Built `BlockBlastBattle-Day20.rbxl`.

### Validation

- `stylua src` passed.
- `selene src` passed with 0 errors and 0 warnings.
- `rojo build default.project.json --output BlockBlastBattle-Day20.rbxl` passed.
- `git diff --check` reported only Windows CRLF notices.

### Notes

- The current direction is a hybrid: Bubble Gum Simulator-style colorful hub controls, BedWars-style low-clutter gameplay.
- Next UI pass should restyle the shop/items panels more heavily using the user-provided shop references.

## Session Update - 2026-08-02 Day19 Compact Hub Card

### Completed

- Replaced the large centered home/hub window with a compact top-left hub card.
- Restyled the card with a lighter simulator-style look instead of the old dark panel.
- Kept only key actions visible: Battle, Story, Shop & Closet, Guide, and close.
- Hid secondary settings/cosmetic controls from the welcome card because they are available through other UI.
- Shortened the daily bonus hub message so the welcome card does not become a paragraph.
- Built `BlockBlastBattle-Day19.rbxl` for testing.

### Validation

- `stylua src` passed.
- `selene src` passed with 0 errors and 0 warnings.
- `rojo build default.project.json --output BlockBlastBattle-Day19.rbxl` passed.
- `git diff --check` reported only Windows CRLF notices.

## Session Update - 2026-08-02 Day18 Gameplay HUD Cleanup

### Completed

- Hid the left player HUD and right action rail automatically during active Battle, Story, and Custom Lab runs.
- Closed any open HUD menu when gameplay focus begins so panels do not overlap the board.
- Kept the compact top context label visible for match mode/time context.
- Hid the Studio diagnostics panel by default and added an F8 Studio-only toggle.
- Built `BlockBlastBattle-Day18.rbxl` for testing the reduced gameplay clutter.

### Validation

- `stylua src` passed.
- `selene src` passed with 0 errors and 0 warnings.
- `rojo build default.project.json --output BlockBlastBattle-Day18.rbxl` passed.
- `git diff --check` reported only Windows CRLF notices.

### Notes

- This is an immediate cleanup pass, not the full UI redesign.
- Recommended visual direction after online reference review: playful Bubble Gum Simulator-style hub HUD, but BedWars-style minimal HUD during actual gameplay.

## Session Update - 2026-08-02 Day17 Color, Custom Lab, and Local Organization

### Completed

- Added a server-authoritative `Hand` RemoteEvent for Custom Lab piece modification.
- Added Custom Lab as a solo mode launched from the local Modes menu.
- Added server validation and cooldowns for Custom Lab `Rotate` and `Reroll` actions.
- Updated shared block generation so every hand receives cloned shape cells instead of shared definition tables.
- Added `Blocks.rotateShape` with normalized rotated cells for safe piece rotation.
- Kept Custom Lab non-progression: no coins, XP, wins, Story Stars, or purchase/cosmetic grants are awarded.
- Added Custom Lab labels, Rotate/Reroll controls, selected-piece pulse feedback, and `HandUpdated` notification feedback in the player UI.
- Updated HUD status text so Custom Lab is treated as an active run, like Battle and Story.
- Brightened the hub with rainbow block trails, festival flags, balloons, plaza confetti, and stronger colorful side-island accents.
- Brightened the fallback hub with rainbow blocks and flower markers so a builder failure no longer looks like a blank/broken map.
- Added `.vscode/settings.json`, `BlockBlastBattle.code-workspace`, `BLOCK_BLAST_START_HERE.md`, and `scripts/open-latest-local-build.ps1`.
- Added VS Code tasks for `Rojo: Build Day17` and `Studio: Open Latest Local Build`.
- Documented that Roblox Studio account selection is controlled by Studio login state and must be verified as `CAPTINNINJATACO` before Play/publish.
- Formatted with Stylua, linted with Selene, checked diff whitespace, and built `BlockBlastBattle-Day17.rbxl`.

### Files Modified

- `src/shared/game/Blocks.luau`
- `src/server/services/GameServer.server.luau`
- `src/server/world/HubBuilder.luau`
- `src/client/ui/BlockBlastClient.client.luau`
- `src/client/ui/HUDController.luau`
- `.vscode/settings.json`
- `.vscode/tasks.json`
- `README.md`
- `BLOCK_BLAST_START_HERE.md`
- `BlockBlastBattle.code-workspace`
- `scripts/open-latest-local-build.ps1`

### Current State

- Latest local build: `BlockBlastBattle-Day17.rbxl`.
- Custom Lab is a first playable vertical slice for adjustable block gameplay: players can start the mode, select a piece, rotate it, reroll it, place it, and return safely.
- The hub is more colorful, but still needs real Studio camera review to confirm the new details land visually from player perspective.
- Roblox Studio MCP remains unavailable from Codex, so Studio playtesting was not claimed.
- The account issue is documented and safer to avoid, but Codex did not modify Roblox credentials. Studio must be signed into `CAPTINNINJATACO`.

### Known Issues

- Custom Lab is intentionally basic: it supports rotate/reroll but not a full saved loadout editor yet.
- Custom Lab `Play Again` is hidden for now; restart through Modes after returning to hub.
- The map still needs user-facing Studio review because repository validation cannot prove camera framing, spawn feel, or color balance.
- Old `.rbxl.lock` files may remain if Studio had older builds open; VS Code now hides them by default.

### Recommended Next Priorities

1. Open `BlockBlastBattle-Day17.rbxl` locally and verify Studio is signed in as `CAPTINNINJATACO`.
   This prevents accidental testing/publishing from the wrong account and confirms the correct newest build is open.
2. Playtest the new colorful hub from actual spawn camera.
   The user specifically disliked the map; player-camera art review is the highest-value next check.
3. Test Custom Lab end to end.
   Start from Modes, rotate/reroll each piece, place pieces, force out-of-moves, and confirm no progression is granted.
4. Build a fuller loadout editor if Custom Lab feels good.
   The new server foundation can grow into saved shape presets and rule variants.
5. Continue UI animation polish around board placement, mode transitions, and result presentation.

### Release Readiness

- Estimate: prototype moving toward vertical-slice quality, roughly 35% of the way to public release.
- Biggest blocker: Roblox Studio playtesting on the correct account and device layouts.
- Biggest gameplay weakness: Custom Lab exists but does not yet have saved presets, matchmaking rules, or tutorialization.
- Biggest polish opportunity: actual Studio camera pass on hub colors, landmarks, and first-spawn wow factor.
- Biggest technical risk: untested Studio runtime behavior for the new `Hand` remote and Custom Lab state path.

## Session Update - 2026-08-01 HomePanel Extraction

### Completed

- Added `src/client/ui/HomePanel.luau` as the owner of the modernized home/hub visual subtree.
- Moved the hub panel, side logo reopen control, status and matchmaking labels, story preview, Battle/Story/Shop/Guide/Settings buttons, cosmetic swatches, board preview cells, home responsive scale, home show tween, queued pulse tween, and home focus paths out of `BlockBlastClient.client.luau`.
- Kept networking, matchmaking authority, tutorial state, settings values, shop/story/cosmetic modal orchestration, gameplay state, and save calls in `BlockBlastClient.client.luau`.
- Preserved the previous Day8 home appearance and cross-input `Activated` behavior.
- Preserved the existing "Arenas Full" battle activation path so the server remains the source of truth for queue rejection.
- Reduced `BlockBlastClient.client.luau` from 2450 lines to 2078 lines at the first clean validation point.
- Added `docs/STUDIO_MCP_VALIDATION.md` with official Studio MCP setup steps, safe local place opening instructions, and the full unexecuted validation matrix.
- Formatted with Stylua, linted with Selene, and built `BlockBlastBattle-Day9.rbxl`.

### Current State

- Repository validation passes locally.
- Official Roblox Studio MCP is not connected in this Codex session, so Studio playtesting and screenshots remain unexecuted.
- `HomePanel` owns its connections and tweens and exposes an idempotent `Destroy` method.
- `BlockBlastClient.client.luau` still owns the gameplay HUD and tutorial panel; those are intentionally outside this extraction.

### Recommended Next Priorities

1. Connect Roblox Studio MCP through Studio Assistant Quick Connect and execute `docs/STUDIO_MCP_VALIDATION.md`.
   The extraction builds, but actual focus/device behavior needs Studio proof.
2. Fix any Studio-discovered UI regressions from the HomePanel extraction.
   Focus order, hidden-element focus, and mobile safe-area layout are the likeliest places for real-device issues.
3. Consider extracting the tutorial panel after Studio validation.
   It is adjacent to the home flow but was left in the client to keep this extraction focused.

## Session Handoff - 2026-07-29

### Completed

- Finished the in-flight Story Missions feature and left it fully wired into the hub.
- Added `src/client/ui/StoryPanel.luau`, a reusable client UI module that lists four nearby story chapters: recently completed replay options, the next playable chapter, and a locked upcoming preview.
- Updated `src/client/ui/BlockBlastClient.client.luau` to require `StoryPanel`, open it from the hub Story button, refresh it from hub state, and hide it when a run starts.
- Updated `src/server/services/GameServer.server.luau` so story runs accept a requested chapter, validate that chapter on the server, expose `storyMissions` in hub state, and prevent replayed chapters from awarding extra Story Stars.
- Preserved the existing tutorial `Try Story` shortcut as a quick-start path into the next unlocked story chapter.
- Completed final persistence hardening: `GameServer.server.luau` now clamps profile integers to explicit bounds, rejects NaN/infinite/bad profile values, sanitizes outgoing save payloads, and reports sanitized-field counts through hub analytics.
- Updated `BlockBlastClient.client.luau` Studio diagnostics to show `Profile L/S/Sanitized` so corrupt profile cleanup is visible during playtests.
- Latest clean build is `BlockBlastBattle-Day4.rbxl`; Day 3 may remain locked if Studio has it open.

### Current State

- The project is stable at a clean stopping point after the Story Missions panel work.
- No intentionally partial code remains from this session.
- The story mission list is intentionally compact: it shows a small rolling window around player progress instead of every possible repeated chapter.
- Story replay currently grants normal score-based coins/XP but only awards the bonus Story Star and completion bonus for the next unbeaten chapter.
- Studio/live validation is still required for the new modal UI interactions, ProximityPrompt story start path, and DataStore-backed Story Stars reload behavior.
- No partially completed features remain from the final persistence-hardening task.

### Recommended Next Priorities

1. Run Roblox Studio local server playtests.
   This is the biggest release blocker because matchmaking, arena isolation, rewards, replay, sudden death, and story selection all need proof in real multiplayer clients.
2. Validate mobile and small-screen UI.
   The game depends heavily on UI board interaction; mobile layout failures would immediately hurt first-time players.
3. Continue server-authoritative economy hardening.
   Rewards, cosmetics, replay, and story progression now have more paths, so abnormal lifecycle tests should come before adding monetization or inventory.
4. Improve the hub environment and signposting.
   Players need to understand battle queue, story missions, cosmetics, and settings within the first 60 seconds.
5. Add original audio polish and mix controls.
   Current cue IDs are placeholders suitable for prototype feedback, not final release polish.
6. Expand story content and retention loops.
   The mission framework works, but the campaign needs more objective variety and reasons to return.

### Technical Debt

- `BlockBlastClient.client.luau` remains large despite extracting `ResultPanel`, `CosmeticPanel`, `SoundController`, and `StoryPanel`.
- Story missions are still static config data and repeat in a simple cycle after the current set.
- Cosmetic unlocks are progression-derived; there is no true owned inventory, shop rotation, or purchase-free collection flow yet.
- Client effects are still mostly UI tweens; particle/audio polish should be centralized before launch.
- Analytics are in-memory Studio diagnostics only, not a production analytics pipeline.

### Ideas

- Add a mission map or chapter path in the hub instead of only a modal list.
- Add daily/weekly non-monetized challenges that use the story objective system.
- Add a practice sandbox where players can freely test block shapes without rewards.
- Add arena visual themes tied to board skins or player level.
- Add accessibility presets for color contrast, motion, and larger board cells.
- Add post-match commendations such as `Most Lines Cleared`, `Clutch Finish`, or `Clean Board`.

### Release Readiness

- Estimate: early prototype, roughly 25-30% of the way to a public Roblox release.
- Biggest blockers: Studio multiplayer validation, mobile playability, persistence confidence, moderation/anti-exploit coverage, and content depth.
- Biggest gameplay weaknesses: battle pacing still needs hands-on tuning, story content is short, and the board exists only as UI rather than a more embodied arena experience.
- Biggest polish opportunities: hub visual identity, final sound design, transitions, particles, thumbnails/icons, and better first-session onboarding.
- Biggest technical risks: server session lifecycle edge cases, DataStore behavior under failure, replay/reward duplication paths, and UI scaling across Roblox devices.

### Final Task Files Modified

- `src/server/services/GameServer.server.luau`
- `src/client/ui/BlockBlastClient.client.luau`
- `DEVELOPMENT.md`

### Single Highest-Priority Next Task

- Run the Roblox Studio local server stress-test checklist in `docs/MULTIPLAYER_STRESS_TEST.md`.
  This should happen next because the code now has enough matchmaking, rewards, persistence, story selection, and sudden-death behavior that real multi-client validation is more valuable than another local-only feature.
## Session Update - 2026-08-13 Day37.2.2 PC Workspace Layout Rebuild

### Completed

- Rebuilt the PC Solo Puzzle workspace into a measured arcade-console hierarchy: header, content region, left stats column, center board/tray column, and right leaderboard/action column.
- Replaced scattered panel offsets with named `WINDOW_LAYOUT` constants for shell size, padding, columns, board, tray, gaps, and action spacing.
- Recomputed board cells from the actual square grid area: `floor((408 - 36 - 35) / 8) = 42`, producing a complete 407px used board inside the 408px board stage.
- Kept exactly 64 logical `TextButton` cells from the existing 8x8 loop and constrained glossy block/shadow children inside each cell to prevent visual bleed.
- Moved the piece tray fully below the board with a 14px measured gap and larger piece previews.
- Forced final readable contrast for Combo, Coins, and Rank refresh paths instead of relying only on helper defaults.
- Rebalanced Server Top into the right column with compact rows and functional actions directly beneath it.
- Suppressed duplicate external HUD/gameplay status elements while the puzzle workspace is open and restored hub HUD focus on return.
- Built `BlockBlastBattle-Day37-2-2.rbxl`.

### Current State

- Studio screenshot/runtime capture was not available in this session, so the checkpoint requires Yoel's visual approval in Roblox Studio.
- Source validation confirms the board remains exactly 8x8 logically and the board/tray heights fit within the PC workspace at the shared workspace scale.
- Existing drag, resize, Reset Layout, board placement, scoring, combo, coins, best score, Server Top, Return Hub, and Play Again code paths were preserved.

### Next Priority

- Open `BlockBlastBattle-Day37-2-2.rbxl` in Studio and inspect the PC Solo Puzzle at default, minimum, and maximum workspace scale. This is highest priority because the previous failure was visual/runtime layout mismatch, not a compile issue.

## Session Update - 2026-08-13 Day37.2.3 Board Hierarchy Fix

### Completed

- Traced Yoel's reported 65th grid item to `ArcadeUI.Panel(boardFrame)`, which added `ArcadeTopHighlight` as a direct `Frame` child beside the `UIGridLayout` and 64 cells.
- Added a dedicated `BoardGridContainer` inside `BoardFrame`; `BoardFrame` now owns board-wide rim/highlight decoration, while `BoardGridContainer` owns only `UIPadding`, `UIGridLayout`, and the 64 cell buttons.
- Added one-time development validation that warns if the grid container has anything except 64 direct `GuiObject` cell buttons with unique in-bounds coordinates.
- Stored `BoardX`, `BoardY`, and `IsBoardCell` attributes on each cell button and made placement/hover use those attributes.
- Fixed the remaining left stat contrast by removing text-label gradients from Combo, Coins, and Rank labels and switching those labels to RichText headings/values.
- Built `BlockBlastBattle-Day37-2-3.rbxl`.

### Current State

- Source validation confirms the grid-layout parent no longer receives board-wide decorative GuiObjects.
- Studio runtime verification still needs Yoel because Studio screenshot capture/control was not available in this session.

### Next Priority

- Open `BlockBlastBattle-Day37-2-3.rbxl` in Studio and confirm the top-left cell is a normal square, no clickable cell appears below the board, and stat text is readable.
