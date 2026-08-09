# Day34 Official Visual Specification

The three attached Day34 references are the active design target. They should be treated as blueprints for the current solo puzzle product.

## Reference 1 - Toybox Map

1. Main colors: saturated cyan, royal blue, yellow, orange, red, lime green, purple, dark navy trim, warm light stone, bright grass.
2. Panel shapes: chunky rounded rectangles, thick slabs, circular platforms, tubes, slides, capsule buttons.
3. Outline thickness: heavy dark outlines and trim, usually 3-6 studs in world scale or 3-5 px in UI scale.
4. Corner radius: large pill corners on buttons, soft bevel-like corners on blocks, rounded machinery housings.
5. Shadow style: soft cartoony contact shadows, dark underside trim, layered object depth.
6. Highlight style: glossy top highlights, bright cyan edge glow, small sparkle accents.
7. Text hierarchy: huge single-purpose labels like PLAY and HIGH SCORES, short readable signs, high contrast.
8. Board proportions: board is a visible product object in the world, but the UI board owns gameplay.
9. Cell styling: dark inset grid with glossy colorful blocks.
10. Piece styling: rounded toy bricks with subtle studs/embossing.
11. Button styling: oversized cyan central Play button with white top lip and orange base.
12. Leaderboard styling: tall framed high-score board with gold/yellow rivets and dark display.
13. Decorative motifs: toy blocks, pipes, slides, bounce pads, conveyor/machine, ramps, chunky arrows, colorful platforms.
14. Map materials: SmoothPlastic, Plastic, Slate/Concrete-like stone, limited Neon for readable accents only.
15. Map object scale: oversized interactive props that read from spawn; dense but navigable.
16. Lighting style: bright daylight, saturated sky, soft bloom, cheerful contrast.
17. Animation style: looping spinners, moving platforms, bouncing pads, dispensing blocks, subtle machine motion.
18. PC/mobile differences: map remains visible behind UI; mobile focuses board and hand tray more aggressively.
19. Shared elements: big score, best score, coins, settings/close, leaderboard access, dark-blue board frame, glossy pieces.
20. Assets to rebuild: button frames, coin chip, close/settings buttons, score capsule, leaderboard board, toy-block icon language.

## Reference 2 - PC Puzzle UI

- Main board centered and dominant, with a dark navy rounded outer frame and cyan edge lighting.
- Left score stack: Score, Best, Combo, Coins, Rank.
- Right leaderboard stack: `SERVER TOP` list with rank badges, avatar slots, player names, and real scores.
- Bottom hand tray: three large pieces in a dark rounded tray.
- Buttons: top-right coin chip plus settings/help/close round-square controls.
- Map background remains visible and slightly secondary behind UI.
- No fake values are allowed; all numbers must use live state/leaderstats.

## Reference 3 - Mobile Puzzle UI

- Tall portrait layout with massive centered score capsule at the top.
- Best score sits directly below the score.
- Board takes most of the middle screen.
- Combo appears as a playful badge near the board.
- Hand tray spans the bottom with three large touch targets.
- Leaderboard collapses into a compact `TOP SCORES` button/drawer affordance.
- Controls stay thumb-friendly and clear of Roblox safe areas.

## Current Roblox Implementation Notes

- Day34 should build the references from Roblox UI instances and source-generated Parts first.
- No full-screen screenshot should be used as the working UI.
- Local PNG asset upload is not available from this Codex session, so Day34 uses Roblox-native Frames, gradients, strokes, text, and Parts. Future uploaded assets should follow this spec.
