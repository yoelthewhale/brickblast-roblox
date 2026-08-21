# Visual Direction — Bubblegum Toybox

**Status: approved and settled.** Decided by Yoel on 2026-08-19. This is no
longer an open design question, and no agent or contributor needs to
re-litigate it. If you are picking up visual work, start here.

Tracked on GitHub by the Bubblegum Toybox visual-overhaul umbrella issue.
This file holds the *direction*; the umbrella issue holds the *phases and
status*. Keep them from drifting: describe intent here, progress there.

The concrete implementation plan against the approved 2026-08-21 reference
mockup lives in [`VISUAL_TARGET_SPEC.md`](VISUAL_TARGET_SPEC.md): element-by-
element classification, the asset inventory, token mapping, and phasing. That
reference shows **one flavor at low energy** (Bubblegum, stage 1) -- it is a
composition target, not an instruction to make the game permanently pink.

---

## The direction in one paragraph

BrickBlast should read as a **bubblegum toybox** — a bright, soft, chunky,
tactile plastic-toy world. Rounded forms, candy-adjacent colors, glossy
highlights, satisfying physical-feeling pieces. The hub already gestures at
this (`HubBuilder.luau` literally builds a `BubblegumSoloHub`); the gameplay
screen does not yet, and the menus read as bolted-on from a different game
(#50). The overhaul's job is to make one coherent visual language across the
whole experience.

## The part that is easy to get wrong

**The game must not become one static color palette.**

A single flat theme applied everywhere would be a regression, not a redesign.
Today the game already changes its look as a run intensifies, and that dynamic
progression is a feature worth protecting and amplifying — not flattening into
brand consistency.

The correct model is: **one recognizable visual identity that becomes
increasingly energetic as the player progresses.** Bubblegum Toybox is the
*identity*; intensity is a *dimension* that moves within it. A player at
stage 1 and a player at stage 12 on a hot combo streak should look obviously
like the same game, and obviously not like the same moment in it.

Parts of the experience that should evolve with combo / stage / run intensity:

- the actual 8x8 board
- the pieces, where appropriate
- board accents
- HUD accents
- combo and stage presentation
- effects
- atmosphere and background treatment

Parts that should stay stable so the identity holds: overall form language
(rounded, chunky, glossy), typography, layout structure, and the meaning of
colors that carry information rather than mood.

## Where the progression system lives today

- `src/shared/game/StageVisuals.luau` — the **live** system that drives
  progression-based color. This is the one to build on.
- `StageProgression.paletteForStage` — a **dead** parallel palette system that
  duplicates the live one (#60). Resolve this as part of the token work rather
  than leaving two sources of truth.
- `src/client/ui/ArcadeUI.luau` — arcade visual helpers, animations, and the
  reduced-motion conventions every new effect must follow.
- `src/client/ui/UITheme.luau` — shared theme values for the older HUD/menu
  system, which is part of why the menus look bolted-on.

## Phasing

The umbrella issue tracks these; they are listed here so the intent survives
even if the issue is reorganized.

1. Visual tokens / theme architecture
2. Objective visual bug fixes
3. Board and piece redesign
4. Gameplay HUD redesign
5. Progression-driven visual states
6. Juice and effects
7. Menus, shop, cosmetics, results
8. Hub polish
9. Typography and consistency sweep
10. Mobile and device visual verification

The first milestone is deliberately narrow: **make the active Solo gameplay
experience look dramatically better.** Hub, menus, and shop come after.

## What this work must not disturb

The technical foundation is in good shape and was verified in a real Studio
session on 2026-08-19. Visual work is presentation-layer work; none of the
following should change to serve it:

- the 8x8 gameplay invariant (exactly 64 direct cell buttons under
  `BoardGridContainer`, no decorative direct children — see AGENTS.md)
- scoring and placement logic
- DataStores, profile migration, and save/load safety
- security, server authority over currency, purchases and receipts
- `SoloLayout`, the phone stacked layout, the touch pipeline, portrait lock
- `VisualQuality` and `UIControlRules`
- telemetry and error reporting
- the local-register CI guard (`scripts/check-local-registers.luau`)

Two of these deserve emphasis, because visual work is exactly the kind of work
that trips them:

- **Do not add top-level `local`s to `BlockBlastClient.client.luau`.** It sits
  at 198 of 200. New visual code belongs in a ModuleScript or on the existing
  `day43Ui` table. See CONTRIBUTING.md.
- **Every new effect needs a reduced-motion alternative**, matching the
  existing convention in `ArcadeUI.luau`. This is an accessibility
  requirement, not a nicety.
