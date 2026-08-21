# Visual Target Spec — Bubblegum Toybox

Implementation blueprint translating the approved 2026-08-21 reference mockup
into work against the real codebase. Companion to
[`VISUAL_DIRECTION.md`](VISUAL_DIRECTION.md), which holds the *direction*; this
file holds the *plan*. Tracked by #98.

**The reference is a composition target, not a palette swap.** What is being
adopted is hierarchy, spacing, chunkiness, candy depth, readable dark-purple
text on light surfaces, and board/results treatment. The all-pink presentation
in the mockup is **one flavor at low energy** — Bubblegum, stage 1. It is not
the game's permanent look.

Everything in `VISUAL_DIRECTION.md` still holds: identity is fixed, flavor
varies by stage, energy varies with run intensity. The reference does not
replace that model; it shows what one point in it should look like.

---

## 1. Current-state diagnosis

Verified against master at the time of writing.

**Already aligned with the reference:**

- `VisualTokens` provides identity / flavor / energy with cream surfaces and
  deep-grape ink — the same relationship the reference uses.
- `ArcadeUI.Color` derives from `VisualTokens.chrome()` (PR #112), so the
  chassis is candy rather than the old near-black arcade cabinet.
- Text roles are contrast-derived and hold ≥ 4.5:1.
- Pieces have gloss, hue-derived outlines, and a grape drop shadow.
- The Solo layout already has the reference's coarse structure: a stat column,
  a centered board, a tray, and a leaderboard.

**Not yet aligned:**

| Gap | Detail |
| --- | --- |
| Two theme systems remain | `UITheme.luau` still drives the older menus and `ResultPanel`. This is the last palette split (#50). |
| Stat cards are not the reference's cards | Desktop renders a vertical stack of labels; the reference wants chunky rounded cards with a small label above a large value. |
| No top header strip | The reference's header (stage progress + resource pills + action buttons on one line) does not exist as a unit. |
| Results is a side panel | `ResultPanel` is a 344×214 panel pinned right of centre. The reference wants a centered modal with a scoring breakdown. |
| No soft shadows | Depth currently comes from `UIStroke` and gradients only. |
| Board frame is thin | The reference's board sits in a distinctly inset well with generous padding. |
| Tray slots are plain | The reference shows each piece on its own rounded card. |

**One correctness note:** the board could not have looked right before PR #112,
because `ArcadeUI.BoardCell` painted a navy gradient over every cell that the
client never reset. Any earlier visual judgement of the board predates that fix.

---

## 2. Reference breakdown

Reading the mockup as structure rather than decoration:

1. **A single horizontal header** carrying time, stage progress, resources, and
   actions. One row, one visual weight — this is the biggest hierarchy win.
2. **A left column of four stat cards**, each a rounded card with a small
   uppercase caption and a large value. Score is visually dominant.
3. **A board in a recessed well**, generous padding, cells as soft rounded
   wells rather than dark holes.
4. **A tray of three cards below the board**, each piece centered on its own
   surface.
5. **A leaderboard card on the right** with a light header row.
6. **A results modal** with a large final score on the left and an itemised
   breakdown on the right.

The personality comes from: large border radii, real spacing, a light ground,
one dark ink for all text, and depth from soft shadow rather than hard outline.

---

## 3. Solo HUD blueprint

Classification per element. "REBUILD" means new code in a new module, not new
gameplay.

| Element | Class | Why |
| --- | --- | --- |
| Top header strip | **NEW** | Does not exist as a unit today. Highest hierarchy win in the whole pass. |
| Timer | **REMOVE from spec** | **Solo has no timer.** `endsAt` is `nil` for Solo; `timeLeft` is always 0. See §7. Do not build a timer UI against a system that does not exist. |
| Stage / progression bar | **RESTYLE** | `StageProgression.publicState` already provides `currentStage`, `stageProgress`, `stageProgressRequired`. Data is there; presentation is not. |
| Resource strip (LV / XP / coins / best) | **RELAYOUT** | Values exist via leaderstats and `publicState`. Today they are scattered; the reference consolidates them into one pill row. |
| Action buttons | **RESTYLE** | Keep behaviour, restyle to circular candy buttons. |
| Score card | **REBUILD** | Currently two labels in a shared card with a known collision (#99). Rebuild as a proper card. |
| Combo card | **RESTYLE** | `comboStreak` and `highestCombo` exist. The reference's "x5 / SWEET!" wants a tier word — a pure display mapping from streak, no new system. |
| Coins card | **RESTYLE** | Live coins exist. The "+8" delta is derivable from `CoinsPerHundredScore`. |
| Trophy / rank card | **RESTYLE** | Server high-score list exists (`serverHighScoreList`). Rank is derivable from it. |
| 8×8 board frame | **RESTYLE** | Well treatment and padding only. **Geometry is owned by `SoloLayout` and must not be hand-tuned.** |
| Board cells | **RESTYLE** | Already token-derived post-#112. Needs radius, inner shadow, gloss. |
| Placed pieces | **KEEP** | `GlossyBlock` already matches the reference closely after #112. |
| Piece tray | **RELAYOUT** | Give each slot its own card surface. |
| Selected-piece state | **RESTYLE** | Selection exists; it needs a clearly stronger visual state. |
| Leaderboard | **RESTYLE** | Data and rows exist; restyle to the light card treatment. |
| Return Hub | **RESTYLE** | Keep behaviour and cooldown. |
| Game-over state | **REBUILD** | Currently folded into `ResultPanel`; see §5. |
| Responsive / mobile | **KEEP** | `SoloLayout` phone path is tested (20 tests). **Do not restructure.** Restyle only. |

**Register constraint.** `BlockBlastClient.client.luau` is at 198/200. None of
this may add top-level locals there. New HUD code goes in new ModuleScripts:
`SoloHeader.luau`, `StatCards.luau`, `TrayView.luau`. This also advances
`AGENTS.md`'s "Safe Cleanup Order" item 3.

---

## 4. Hub blueprint

| Element | Class | Why |
| --- | --- | --- |
| Title | **RESTYLE** | Token typography. |
| Resource bar | **RESTYLE** | Same pill treatment as the Solo header — this is what makes the two screens read as one product. Note #45: no overflow handling on phones. |
| Tutorial / help card | **KEEP** | Restyle with the rest. |
| Left-side navigation | **RESTYLE** | The reference's vertical icon rail is close to what exists. |
| Right-side buttons | **RELAYOUT** | Consolidate into one stack with consistent sizing. |
| Play CTA | **RESTYLE** | Must become the single clear primary action. |
| Result / forfeit popup | **RESTYLE** | Currently `UITheme`-driven; move to tokens. |
| Inventory / leaderboard / settings | **RESTYLE** | Covered by #50 — these are the "bolted-on" panels. |
| Blank / dark / unreadable UI | **REBUILD** | Any surface still on `UITheme` reads as another generation of UI. |
| 3D hub world | **KEEP** | Out of scope this pass. UI coherence first. |

---

## 5. Results screen blueprint

The reference's breakdown is the strongest single idea in the mockup. Mapping
it against `state.resultSummary`, which already carries `mode`, `outcome`,
`score`, `linesCleared`, `highestCombo`, `duration`, `coins`, `xp`,
`bestScore`, `previousBestScore`, `won`, and `nextUnlockText`:

| Reference row | Status | Notes |
| --- | --- | --- |
| Final score | **Exists** | `resultSummary.score`. |
| Best / NEW BEST | **Exists** | `bestScore` vs `previousBestScore` — the NEW BEST flag is just a comparison. |
| Stage reached | **Small addition** | Tracked live in `state.stage` but **not copied into `resultSummary`**. One-line server change. |
| Coins earned | **Exists** | `resultSummary.coins`. |
| XP earned | **Exists** | `resultSummary.xp`. |
| Reward / progression preview | **Exists** | `nextUnlockText`. |
| Play Again / Return Hub | **Exists** | Keep behaviour and cooldowns. |
| Lines cleared, highest combo | **Exists, unused** | Free additional rows. |
| **Base score** | **NEW SYSTEM** | Score is accumulated as one running total. Splitting it needs per-source tracking on the server. |
| **Combo bonus** | **NEW SYSTEM** | Same — not tracked separately today. |
| **Time bonus** | **DO NOT BUILD** | There is no Solo timer. This row is a mockup artifact. |

**Recommendation:** build the results modal now using only what exists, plus
the one-line stage addition. Treat the base/combo split as a separate, later
server task — it is a scoring-attribution feature wearing a UI costume, and it
touches `GameServer.server.luau`, which is register-sensitive.

---

## 6. Native UI vs PNG vs effects

**A. Must stay native Roblox UI.** Text and every dynamic number; all buttons;
all cards and panels; the 64 board cells; piece slots; progress bars; the
leaderboard rows; anything positioned by `SoloLayout`. Rationale: these must
scale responsively, recolour per flavor and energy, and stay crisp at every
viewport. Baking them into images would destroy the progression system and the
phone layout in one move.

**B. Should be PNG assets.** Icons, badges, decorative candy flourishes, the
reward crate, particle sprites, and one 9-slice soft shadow. See §7.

**C. Should be Roblox native effects.** Gloss highlights (`UIGradient`); soft
depth (9-slice `ImageLabel` behind cards); all motion (`TweenService`);
particle bursts (`ParticleEmitter` with a PNG sprite); stage-transition washes
(existing `StageVisuals.transitionForStage`); colour response to energy
(existing token pipeline).

---

## 7. PNG asset request list

For ChatGPT generation. All must be PNG with real alpha unless stated.
House style for every asset: soft chunky candy-toy, rounded forms, glossy
highlight upper-left, deep-grape (`#3A1E42`) outlines rather than black, no
text baked in, no drop shadow baked in unless stated.

1. **`icon_coin`** — resource pill and results. 128×128, square, transparency
   required. Glossy gold candy coin, three-quarter face, grape rim light.
   Variants: none.
2. **`icon_xp`** — resource pill and results. 128×128, square, transparency.
   A mint-green candy star or gem, glossy. Variants: none.
3. **`icon_best`** — best-score pill. 128×128, square, transparency. A small
   grape-purple ribbon rosette. Variants: none.
4. **`icon_trophy`** — rank card. 128×128, square, transparency. Chunky candy
   trophy, gold body, pink accents. Variants: none.
5. **`icon_stage`** — stage progress. 128×128, square, transparency. A candy
   flag or pennant on a striped pole. Variants: none.
6. **`medal_rank`** — leaderboard rows. 96×96, square, transparency. Round
   candy medal with a ribbon. **Variants: gold, silver, bronze** (three files).
7. **`crate_reward`** — results reward preview. 512×512, square, transparency.
   Pastel gift crate, slightly open, glow escaping, ribbon. **Variants: closed
   and open** (two files).
8. **`sparkle_particle`** — combo and line-clear bursts. 128×128, square,
   transparency, **white/near-white only** so it can be tinted per flavor at
   runtime. Soft four-point star with a bloom core. Variants: none.
9. **`confetti_particle`** — new-best and stage-up. 64×64, square,
   transparency, **white only** for runtime tinting. A single rounded confetti
   rectangle with a soft edge. Variants: none.
10. **`shadow_soft_9slice`** — depth under every card. 128×128, square,
    transparency, **greyscale/black with alpha falloff only, no colour**. A
    soft rounded-rect shadow with ~24px uniform falloff and a solid centre so
    it 9-slices cleanly. Critical: falloff must be identical on all four edges.
    Variants: none.
11. **`candy_flourish_corner`** — decorative panel corners, used sparingly.
    256×256, square, transparency. A small cluster of candy shapes (gumball,
    swirl, jelly bean) arranged for a top-left corner. Variants: none — mirror
    at runtime for other corners.
12. **`lollipop_mark`** — brand accent on results and hub. 512×512, square,
    transparency. Classic pink-and-white spiral lollipop with a stick, angled.
    Variants: none.

**Deliberately not requested:** buttons, cards, panels, board cells, tray
slots, progress bars, or anything containing text or a number. Those are native
UI so they can recolour with flavor and energy and reflow on phones.

---

## 8. VisualTokens mapping

Existing tokens cover most of this. Families to add, all derived — never
literals:

| Family | Tokens | Reacts to |
| --- | --- | --- |
| Surfaces | `surface`, `surfaceSunken`, `surfaceTinted` | stable (identity) |
| Cards | `cardFill`, `cardEdge`, `cardShadow` *(new)* | `cardFill` stable; `cardEdge` may take a faint flavor tint |
| Borders | `boardCellEdge`, `edge` | flavor |
| Text | `ink` | **stable — never varies** |
| Muted text | `inkSoft` / chrome `muted` | **stable** |
| Candy shadow | `shadow`, `cardShadow` *(new)* | stable |
| Highlights | `gloss`, `glossStrength` | `glossStrength` rises with energy |
| Buttons | `buttonPrimary`, `buttonSecondary`, `buttonInk` *(new)* | primary takes flavor; ink stable |
| Danger | `danger`, `dangerInk` *(new)* | **stable — semantic** |
| Success | `success`, `successInk` *(new)* | **stable — semantic** |
| Board wells | `boardWell`, `boardCell` | flavor + energy |
| Board frame | `surfaceTinted`, `boardRim` | flavor + energy |
| Pieces | `piecePalette` | flavor + energy |
| Leaderboard | `leaderboard`, chrome `gold`/`silver`/`bronze` | stable |
| Progression | `accent`, `hot` | stage + combo + energy |
| Disabled | `disabledFill`, `disabledInk` *(new)* | **stable** |

**Rules.** Anything carrying *meaning* — ink, muted, danger, success, disabled,
rank metals — stays stable, because a player must not have to relearn what a
colour means mid-run. Anything carrying *mood* — board, pieces, accents, rim,
wash, atmosphere — moves with flavor and energy.

All new text roles must go through `VisualTokens.readableOn` so contrast is
derived, not eyeballed.

---

## 9. Progression and energy behaviour

Unchanged from `VISUAL_DIRECTION.md`, restated because the reference makes it
easy to forget:

- **Flavor** (stage) drives which candy family the board and pieces use.
- **Energy** (combo streak, stage depth, perfect clears; `VisualTokens.energyFor`)
  drives saturation, rim heat, accent temperature, wash strength, gloss.
- **Chrome stays stable** — the chassis does not heat up, so the board reading
  as "hot" stays legible. Revisit only if Studio review says otherwise.

The reference must not be implemented by hardcoding its pinks. Every colour in
it should arrive through `VisualTokens.resolve(stage, energy)`.

---

## 10. Interaction and juice

Every effect needs a reduced-motion path, matching the `ArcadeUI` convention.
Reduced motion means *instant state change*, never *no feedback*.

| Trigger | Full motion | Reduced motion |
| --- | --- | --- |
| Button hover | Scale 1.03, gloss brightens | Gloss brightens only |
| Button press | Scale 0.96, shadow contracts | Instant fill darken |
| Piece select | Lift 4px, shadow grows, rim pulses | Static rim highlight |
| Piece drag | Piece follows above the board, cells under it tint | Same, no easing |
| Valid placement | Ghost cells fill at ~55% in the piece colour | Same, instant |
| Invalid placement | Ghost tints `danger`, 6px shake | Static danger tint, no shake |
| Piece placed | Cells pop 1.08 → 1.0, small dust puff | Cells appear filled |
| Single line clear | Sweep along the line, cells flash gloss then collapse | Cells clear instantly |
| Multi-line clear | Staggered sweeps + `sparkle_particle` burst | Instant clear + brief flash |
| Combo up | Combo card pulses, tier word swaps, energy rises | Value and word swap only |
| New stage | Existing `transitionForStage` wash, flavor crossfade | Existing fade path |
| New best | `confetti_particle` burst, score card gold pulse | "NEW BEST" label appears |
| Coins earned | "+n" floats up from the coin card | "+n" appears briefly |
| Game over | Board desaturates, results modal scales in | Board dims, modal appears |

Restraint: at most one celebratory effect at a time. A multi-line clear that is
also a new best should escalate the clear, not fire both.

---

## 11. Gameplay-feel findings (analysis only — no changes proposed here)

### Facts verified in code

1. **Solo has no timer.** `endsAt` is `nil` for Solo; `timeLeft` is always 0.
   The only loss condition is `Grid.hasAnyMove(board, hand) == false`.
2. **Sudden death and garbage are Battle-only.** Both `applySuddenDeathPressure`
   and `pressureOpponents` return early unless `mode == "Battle"`. Solo receives
   no garbage rows. This rules out a common "why did I die" explanation.
3. **The hand refills only when all three pieces are used** — `if not hasPieces
   then giveNewHand(state)`. So the third piece of every hand is disproportionately
   likely to be the one that ends the run.
4. **The assistance budget is small.** `AssistanceStart = 3`, `AssistanceMax = 4`,
   `RescueCost = 1`. At most three rescued hands per run, and #59 confirms
   `lastRestoreReason` is silently dropped, so rescues are invisible to the player.
5. **Difficulty pressure starts at stage 3** and climbs: `PressurePerStage = 0.07`
   to `MaxPressure = 0.42`, then a late curve from stage 9 to `LateMaxPressure = 0.58`
   (extended by Codex in #114). Pressure directly reduces `assistanceMultiplier`
   and raises `restrictiveBias`.
6. **Scoring is flat and unattributed.** `PointsPerCell = 10`, `PointsPerLine = 100`,
   `ComboBonusPoints = 25`. Score accumulates as a single total with no
   per-source breakdown, which is why the reference's results breakdown needs
   new server work.
7. **Stage requirements grow linearly and forever.** `BaseRequirement = 28`,
   `RequirementGrowth = 8`, with no cap (#54).

### Hypotheses requiring playtesting

- Running out of assistance is the actual death mechanism in most runs, and
  because rescues are invisible the player experiences it as sudden unfairness
  rather than as a resource they spent.
- Three restrictive pieces arriving together at stage 3+ is the dominant
  deadlock pattern; the all-three-used refill rule makes it worse.
- Early game may be too *easy* rather than too hard — pressure is zero until
  stage 3 — so the difficulty feels like a cliff instead of a ramp.
- Flat per-line scoring may be why clears do not feel rewarding: a 1-line and a
  4-line clear differ in magnitude but not in kind.
- Because there is no timer and no visible pressure, there may be no felt
  urgency until the run abruptly ends.

**None of this should be acted on without playtesting**, and none of it belongs
in the visual pass. It is recorded here so it becomes a properly scoped Codex
gameplay task later.

---

## 12. Implementation phases

Reordered from the original suggestion for two code-driven reasons: token and
shadow work must precede any card work, and the client monolith must be
relieved before large HUD code lands.

| Phase | Work | Files | Risk | Depends on |
| --- | --- | --- | --- | --- |
| **A** | Token families from §8; `UITheme` folded into tokens | `VisualTokens`, `UITheme` | Low | — |
| **B** | Extract HUD from the monolith into modules **before** restyling | new `SoloHeader`, `StatCards`, `TrayView` | **High** — touches the 198/200 file | A |
| **C** | Soft-shadow + card primitives in `ArcadeUI` | `ArcadeUI` | Low | A, assets 10 |
| **D** | Solo header strip + stat cards | modules from B | Medium | B, C |
| **E** | Board frame, well, cell treatment | `ArcadeUI`, board module | Medium — must not touch `SoloLayout` geometry | C |
| **F** | Piece tray cards + selected state | `TrayView` | Low | B, C |
| **G** | Results modal | new `ResultsView`, small `GameServer` addition for stage | Medium | C; server change is register-sensitive |
| **H** | Gameplay juice | `ArcadeUI`, board module | Medium | E, F, assets 8–9 |
| **I** | Hub UI coherence | `HUDController`, panels | Medium | A, C |
| **J** | Asset integration | `UIAssets` | Low | ChatGPT assets |
| **K** | Responsive verification | — | Low | all |
| **L** | Studio / device QA | — | — | all |

**Phase B is the one to be careful with.** Extracting from
`BlockBlastClient.client.luau` at 198/200 is the highest-risk step in the plan
and the reason #96 happened. It should be its own PR, behaviour-neutral, with
the register ratchet lowered afterwards to lock in the headroom gained.

---

## 13. Responsibility split

- **Claude (this lane):** visual architecture — phases A, C, E, H; token
  design; visual review of merged work; keeping this spec current.
- **Codex:** phases B, D, F, G, I, J — mechanical extraction and
  implementation against this spec; the later gameplay-feel task from §11.
- **ChatGPT:** the twelve assets in §7.
- **Yoel:** Studio and device verification at every phase; the reduced-motion
  and phone passes; the judgement calls flagged below.
- **Tanner:** untouched. No beginner-queue issue is consumed by this plan.

**Decisions that need Yoel:**

1. The reference shows a timer. Solo has none. Options: drop it (recommended),
   add an optional timed mode, or show elapsed time instead.
2. The results breakdown needs score attribution on the server. Worth it, or
   ship the simpler results modal?
3. Should chrome heat up with energy, or stay stable as it is now?

---

## 14. Risks

- **Register limit.** Phase B is the danger. Extract, do not add.
- **`SoloLayout` geometry.** Restyle only. It has 20 tests and owns the phone
  layout, portrait lock, and touch pipeline.
- **8×8 invariant.** Exactly 64 direct children of `BoardGridContainer`, no
  decorative children. Candy flourishes must never be parented there.
- **Contrast regression.** Every new text role goes through `readableOn`.
- **Reduced motion.** Every effect in §10 needs its alternative path.
- **Two agents on one file.** Codex and Claude must not both hold
  `ArcadeUI.luau` or the new HUD modules at once; coordinate on #98.
- **Nothing here has been seen rendered.** No Studio exists in the agent
  environment. Every phase needs a Yoel pass before the next builds on it.
