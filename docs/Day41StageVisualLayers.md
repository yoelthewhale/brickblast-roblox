# Day41 Stage Visual Layers

Stage visuals are client-side presentation state for active Solo runs. They do not change board size, piece shapes, saved cosmetics, profile data, scoring, stage rules, or server authority.

## StageVisuals

`src/shared/game/StageVisuals.luau` maps stage numbers to repeating visual presets. Stages 1-4 are Aqua Candy, Berry Pop, Golden Cheese, and Lava Rush. Stage 5 cycles back to Aqua Candy, Stage 6 to Berry Pop, and so on, while normal stage numbers continue increasing.

The active preset owns:

- full-screen Solo background and subtle decorative backdrop accents
- major Solo panel fills, borders, highlights, and text colors
- board frame, board rim, empty-cell fill, and empty-cell outline
- visual color of existing placed Solo blocks
- visual color of newly placed Solo blocks
- tray-piece preview colors
- score, combo, stage, and accent colors
- Server Top leaderboard accents
- Stage Up notice and transition wash colors

## Cosmetic Themes

Player-owned cosmetic themes remain a separate system. They continue to own hub/non-Solo theme preferences and player-specific cosmetic details where those details do not conflict with the active Solo stage preset.

During active Solo play, stage visuals take priority for the gameplay presentation so a stage reads as one complete world transformation.
