# Visual Direction — Deep Board

**Status: approved and settled.** Decided by Yoel on 2026-08-23, replacing the
Bubblegum Toybox direction that was settled on 2026-08-19. This is not an open
design question, and no agent or contributor needs to re-litigate it. If you
are picking up visual work, start here.

Tracked on GitHub by the visual-overhaul umbrella issue. This file holds the
*direction*; the umbrella issue holds the *phases and status*. Keep them from
drifting: describe intent here, progress there.

---

## Why this replaced Bubblegum Toybox

Bubblegum Toybox was a bright cream chassis with candy-colored pieces, soft
shapes and glossy highlights. It was built, and Yoel's verdict on the built
result was that the game "feels more solid but doesn't quite *look* solid":
the gloss and the light ground read as soft rather than tactile. The direction
was changed against a specific reference image rather than in the abstract.

The Bubblegum work was not wasted and should not be reverted wholesale. The
two-axis token model, the derived-readability machinery, the single source of
truth in `VisualTokens`, and the production icon set all survived the change
intact; only the values and the polarity moved. That is the point of having a
token layer.

## The direction in one paragraph

BrickBlast should read as a **deep board**: saturated, hard-edged, molded
plastic blocks sitting in a dark navy recess, in a slightly lighter indigo
room. The depth comes from bevel and recess, not from gloss or ornament. A
block is a solid with a lit top face and a shaded bottom face; an empty cell
is a hole, not a tile; a panel is cut out of the room rather than laid on top
of it. Nothing on a panel is decorative.

**The hub is deliberately not part of that yet.** `HubBuilder.buildHub` builds
`SimpleSoloHub` -- a bare platform, plaza, spawn, Solo pad, boards and rails --
because Yoel asked for the map to be stripped right down for gameplay testing.
That is a temporary test environment, not the visual direction, and it should
not be read as one.

The candy hub still exists in that file as `_buildToyboxHub`, ~569 lines,
unreferenced. It is now reference material for a superseded direction rather
than a target. Note it is the *second* superseded hub carried in that file --
#32 already tracks ~580 lines of an earlier one -- so rebuilding the hub
environment should be scoped as its own task that resolves both, not as an
incidental part of another change.

## The part that is easy to get wrong

**The game must not become one static color palette.**

A single flat theme applied everywhere would be a regression, not a redesign.
The game already changes its look as a run intensifies, and that dynamic
progression is a feature worth protecting -- not flattening into brand
consistency.

The correct model is: **one recognizable visual identity that becomes
increasingly energetic as the player progresses.** Deep Board is the
*identity*; intensity is a *dimension* that moves within it. A player at stage
1 and a player at stage 12 on a hot combo streak should look obviously like
the same game, and obviously not like the same moment in it.

### What changed about *where* progression lives

Under Bubblegum, stage picked the flavor and the flavor colored the **pieces**.
Under Deep Board it does not, and this is the single most important rule in
this file:

**Block colors are identity, not flavor.** The reference shows five saturated
colors coexisting on one board. `VisualTokens.BLOCK_PALETTE` is fixed, and
`resolve()` returns the same palette at every stage and every energy level.
Tying piece color to stage would fight the look directly, and it would also
mean pieces changing color underneath a player mid-run.

Progression did not get deleted. It moved to the **room**: atmosphere, wash,
rim, accent, and the depth of the board well all still travel with stage and
energy. A hot run still visibly reads as hot. `VisualTokensTests` guards both
halves of this -- that blocks do not vary, and that the room still does -- so
a future palette tweak cannot quietly undo either.

Parts of the experience that should evolve with combo / stage / run intensity:

- the room: background, atmosphere accent, wash
- the board well and its rim
- board and HUD accents
- combo and stage presentation
- effects

Parts that stay stable so the identity holds: the block palette, overall form
language (hard-edged, beveled, recessed), typography, layout structure, and the
meaning of colors that carry information rather than mood.

## Where the progression system lives today

- `src/shared/game/StageVisuals.luau` — the **live** system that drives
  progression-based color. This is the one to build on.
- `StageProgression.paletteForStage` — a **dead** parallel palette system that
  duplicates the live one (#60). Resolve this as part of the token work rather
  than leaving two sources of truth.
- `src/client/ui/ArcadeUI.luau` — arcade visual helpers, animations, and the
  reduced-motion conventions every new effect must follow.
- `src/client/ui/UITheme.luau` — shared theme values for the older HUD/menu
  system. This used to hold an unrelated hand-picked palette ("B2 Polished
  Arcade"), which is why the menus looked bolted-on; it now derives from
  `VisualTokens` like everything else. Do not reintroduce literal colors here.

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
8. Hub environment rebuild (the current `SimpleSoloHub` is a test map, not a
   design; this phase is a rebuild rather than a polish pass)
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
