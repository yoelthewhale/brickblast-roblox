# BrickBlast Gameplay Rules

## Solo Puzzle Core

- The logical board is exactly 8 by 8, using `Config.BoardSize`.
- A Solo run starts with an empty board, score 0, combo 0, stage 1, and a three-piece hand.
- A placement is server-authoritative. The server accepts only a live Solo, Battle, Story, or Custom run with a valid hand slot and a legal grid position.
- Placed cells score `Config.PointsPerCell` each.
- Cleared rows and columns score `Config.PointsPerLine` each.
- A combo advances when a placement clears at least one line and resets to 0 when a placement clears none.
- Combo bonus is `(comboStreak - 1) * Config.ComboBonusPoints`.
- The run is over when the current hand has no legal move after the board and hand update.

## Lines, Combos, And Stages

- `Grid.clearLines` clears every full row and full column after a placement.
- `StageProgression.applyPlacement` awards stage progress for line clears, multi-line clears, combo streaks, and perfect clears.
- A perfect clear is counted only when a line-clearing placement leaves the board empty.
- Stage requirements grow by `Config.StageProgression.RequirementGrowth` per stage.
- Stage visuals are cosmetic. Stage changes do not alter board dimensions or normal placement rules.

## Solo Hand Generation

- Solo uses `HandGenerator.generate`; disabled legacy modes keep the older random hand behavior.
- Available shapes (see `src/shared/game/Blocks.luau` for the exact list, since this grows over time): singles, straight lines (2/3/4 cells, both orientations), the 2x2 square, the 2x3 rectangle (both orientations), a plus, all 4 rotations of the L-tromino corner piece, all 4 rotations each of T/S/Z/J/L tetrominoes, and diagonal pieces (2/3/4 cells, corner-touching only — not edge-adjacent, so they don't tile efficiently and are intentionally the hardest pieces to place).
- The generator evaluates all known shapes against the current board with `Grid.canPlace`.
- Each new hand scores a bounded set of candidate three-piece hands. The default candidate limit is `Config.HandGeneration.CandidateLimit`.
- If any known shape can fit, the chosen hand must contain at least one fitting piece.
- If no known shape can fit, the generator does not invent a move and the legitimate game-over condition is preserved.
- Scoring favors legal-placement breadth, modest line-clear and near-clear potential, small pieces on crowded boards, and combo-continuation chances.
- Scoring penalizes duplicate pieces in one hand, hands recently seen in the run, too many immediately fitting pieces, and too many clear-answer pieces.

## Assistance Limits

- Solo runs carry a small server-side assistance budget.
- Assistance can be spent only when the board is crowded or very few known shapes fit.
- Spending assistance increases the score weight of playable, flexible rescue pieces for that hand only.
- Assistance is not unlimited. It starts at `Config.HandGeneration.AssistanceStart`, caps at `Config.HandGeneration.AssistanceMax`, and spends `Config.HandGeneration.RescueCost`.
- Assistance can be restored by stage advancement, combo milestones, and perfect clears, but never above the cap.
- Assistance does not guarantee a combo, perfect clear, exact placement, or three perfect answers.
- Later stages add pressure by reducing assistance weight and slightly favoring more restrictive pieces.

## Developer Diagnostics

- Authorized developer diagnostics may show current stage, pressure, score, combo, occupied cells, current hand, legal placements per current piece, assistance budget, last assistance reason, candidate count, record eligibility, and visible board cell count.
- Diagnostics are read-only and do not mark a run as a developer test run.
- Gameplay-changing developer commands still mark records disabled.

## Achievements And Lifetime Stats

- `src/shared/game/Achievements.luau` defines tiered achievements (Bronze/Silver/Gold) across 7 lifetime stat categories: best score, highest combo, highest stage, total perfect clears, total lines cleared, total blocks placed, and total runs completed.
- Lifetime stats are separate from per-run state and persist across runs in the player's profile, sanitized and clamped the same way every other saved stat is.
- Achievements are checked server-side after every placement and again at run completion; unlocking one grants a one-time coin reward and fires a client notification immediately.
- Developer test runs and Custom Lab never contribute to lifetime stats or achievements, matching every other reward path in the game.

## Redeemable Codes

- Players can redeem a code from the hub's Codes panel; redemption is validated server-side and each code can only be redeemed once per player (tracked in the saved profile).
- The `yoel` code is a developer/testing code: it maxes out coins, XP, level, and story stars, and unlocks every cosmetic including gamepass-locked ones. It is intentionally not restricted to a specific account — this is a private project for a small group, not a live game with a real economy to protect.

## Balance Notes

- The intended feel is smart-but-not-automatic: most fresh hands should offer useful choices, while poor placement and crowding can still end the run.
- Future balance work should use deterministic simulations and Studio play checks before changing candidate limits, assistance budget, or stage pressure.
- Powerups, monetization, mobile changes, and map changes are still outside this rules checkpoint.
