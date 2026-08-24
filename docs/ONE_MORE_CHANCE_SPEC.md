# One More Chance — Panel Spec

Player-facing spec for the Solo revive offer. Owns the panel, the copy, the
token surfacing, and the hand-refresh moment. Deliberately
**implementation-neutral**: the same panel serves a free prototype, a
token-redemption, and a Robux purchase, because the first build is expected to
be free/token-based and gain Robux later.

Design lane: Claude. Game logic, server state, receipts and token fulfilment:
Codex. This file says what the player sees and why; it does not prescribe how
the run is restored.

---

## 1. When it appears

**Only at a true fail state.** The Solo run has reached a board with no legal
move for any piece in hand. Never mid-run, never as an upsell, never on a
timer, never on a stage transition.

The run must be held in a pending state rather than finalized, so the offer has
something to revive. That is Codex's side; the panel simply assumes the run is
recoverable while it is on screen.

---

## 2. Anti-pressure rules

These are the difference between a lifeline and a shakedown. Treat them as
requirements, not preferences.

- **No countdown timer anywhere on the panel.** Not on the offer, not on the
  button, not as a progress ring. A ticking clock on a paid prompt is the
  clearest dark pattern in this genre and the single thing most likely to make
  this read as predatory.
- **`End Run` gets equal visual weight.** Same button height, same text size,
  same contrast. It may be visually quieter in colour — secondary rather than
  accent — but it must never be greyed, shrunken, hidden behind a corner `X`,
  or made to look disabled.
- **`One More Chance` is never the default focus.** Keyboard and gamepad focus
  starts on `End Run`. A player mashing A/Enter at the moment they lose must not
  accidentally spend anything.
- **Price is shown before the Roblox dialog**, once a paid version exists. The
  player learns the cost from our panel, not from Roblox's purchase prompt.
- **The cap is disclosed up front**, on first sight, not discovered on a second
  attempt. See §4.
- **Cancelling returns to the offer, it does not end the run.** A cancel is not
  a decision to quit. The player lands back on the same two choices.

---

## 3. Layout

Consumes `VisualTokens`; no literal `Color3` values. Reuses the modal pattern
established by `ModeSelectPanel` (shaded backdrop, centred card, `Radius.panel`,
`boardRim` stroke) so the two read as the same product.

```
┌─────────────────────────────────────┐
│  No moves left                      │   title, ink, GothamBlack
│  Stage 7 · 12,480 points            │   run summary, inkSoft
│                                     │
│  ┌───────────────────────────────┐  │
│  │  [board preview or crest]     │  │   see §6
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  ONE MORE CHANCE              │  │   accent fill, ink text
│  │  Rewind one move and get a    │  │   subline, inkSoft
│  │  fresh hand that fits         │  │
│  │  Free · 1 of 1                │  │   entitlement line, §4
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  END RUN                      │  │   surfaceSunken fill, ink text
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

The backdrop shade must be opaque enough that the dead board is not competing
for attention, but the run summary line carries the emotional weight — the
player should see what they are about to lose.

**Phone layout:** the panel is width-constrained by `SoloLayout`'s content
width, buttons go full-width stacked, and the board preview drops first if
vertical space is tight. The two buttons must never end up side by side on a
phone — side-by-side invites a mis-tap on the one that costs something.

---

## 4. States

The same panel, five entitlement states. Only the entitlement line and the
primary button's availability change.

| State | Entitlement line | Primary button |
| --- | --- | --- |
| Free continue available | `Free · 1 of 1` | enabled |
| Saved token available | `Using your saved One More Chance` | enabled |
| Purchasable | `R$ NN · 1 of 1` | enabled |
| Cap reached this run | `Already used this run` | **hidden, not disabled** |
| Not available | — | **hidden** |

When the cap is reached, **remove the primary button rather than showing it
greyed.** A disabled paid button is an advertisement for a thing the player
cannot have at the moment they are least receptive to it. The panel becomes a
clean "no moves left / End Run" screen.

---

## 5. Copy

Exact strings. Written to promise precisely what is delivered and nothing more.

| Element | Text |
| --- | --- |
| Title | `No moves left` |
| Run summary | `Stage {n} · {score} points` |
| Primary button | `ONE MORE CHANCE` |
| Primary subline | `Rewind one move and get a fresh hand that fits` |
| Secondary button | `END RUN` |
| Token notice (see §7) | `You have a saved One More Chance` |

**Why not the alternatives.** `Undo your mistake` over-promises: `hasAnyMove`
fails *after* placement, so the move that ended the run frequently is not the
move that doomed the board — it may have been unwinnable several turns earlier.
Rewinding one placement often restores a board that is still dead, and what
actually saves the run is the guaranteed-fitting hand. The undo largely buys the
*feeling* of fixing a mistake, which is a legitimate thing to offer but must not
be described as more than it is.

`Save Run` is vaguer and says nothing about the mechanics. `Continue` is
genre-generic and carries no warmth. `One More Chance` is warm, fits Bubblegum,
and claims nothing false.

Avoid entirely: any second-person urgency (`Don't lose your run!`), any
exclamation mark on the paid path, any framing of `End Run` as giving up.

---

## 6. The hand-refresh moment

The point where this either feels generous or transactional.

When the continue is granted, the fresh pieces must arrive as a **gift, not a
tray refill.** Distinct from the normal hand-refill animation:

- The board briefly re-saturates from its dead/desaturated state back to the
  run's live energy colour, using the existing energy pipeline.
- The three new pieces enter with a staggered pop-in, slightly larger and later
  than the standard tray entrance, settling into place.
- A single soft `sparkle_particle` burst tinted to the current flavor. **One**
  burst — this is a reprieve, not a jackpot.
- No coin/currency imagery anywhere in this moment, even on the paid path. The
  player has already paid; reminding them is graceless.

**Reduced motion:** board colour returns instantly, pieces appear in place, no
particles. The player still sees the state change clearly — reduced motion means
instant, never absent.

---

## 7. Token surfacing

**The fallback is worthless if the player never learns they have it.**

If a purchase is fulfilled while no live run exists, Codex grants a persisted
token. From the player's perspective that is currently invisible, which
reproduces the exact failure the token was designed to prevent.

Two surfaces, both required:

1. **On hub entry after a token is granted** — a one-time notice through the
   existing notification controller: `You have a saved One More Chance`. Fires
   once per grant, not every join. Same hold-until-client-ready pattern used for
   the profile-load notice (#26), so it cannot be dropped before the client is
   listening.
2. **On the panel itself** — the entitlement line reads
   `Using your saved One More Chance` so redemption is legible at the moment it
   happens.

Optional third surface, worth considering: a small persistent indicator in the
hub while a token is held. Not required for the first build.

---

## 8. What the panel needs from the server

The data contract. Implementation-neutral — the panel does not care whether the
entitlement came from a free allowance, a saved token, or a purchase.

```
continueOffer = {
    available    : boolean,   -- may the player continue at all
    source       : string,    -- "free" | "token" | "purchase" | "none"
    usedThisRun  : number,    -- continues already spent
    capThisRun   : number,    -- currently 1
    priceText    : string?,   -- display string, purchase source only
    stage        : number,    -- for the run summary line
    score        : number,    -- for the run summary line
}
```

The client renders from this and nothing else. It never decides entitlement,
never computes price, and never assumes a source. Adding a Robux path later
means `source` becomes `"purchase"` and `priceText` populates — no panel
rewrite.

---

## 9. Telemetry the panel is responsible for

Codex owns fulfilment telemetry. These are the presentation-side events:

- `continueOfferShown` — with `source` and `usedThisRun`
- `continueOfferAccepted`
- `continueOfferDeclined` — `End Run` pressed
- `continueOfferCancelled` — purchase dialog dismissed, returned to offer
- `continueTokenNoticeShown`

The decline-versus-cancel split matters: a high cancel rate after seeing the
price is a pricing signal, while a high decline rate is a desirability signal,
and conflating them would hide both.

---

## 10. Leaderboard

**Provisional decision (Yoel):** continued runs count on the normal
leaderboard, capped at one continue per run, with telemetry recording whether a
continue was used.

Recorded here because the panel does **not** need to disclose anything today —
a single free continue that everyone gets is not an unfair advantage.

**Flagged for revisiting when the Robux path lands.** At that point a paid
continue that counts on the normal leaderboard is, straightforwardly, buying
score. The mitigation is already in place: because telemetry records whether a
continue was used, continued and uncontinued runs can be separated later without
losing history. If the decision changes, the panel gains one disclosure line;
nothing else here moves.

---

## 11. Out of scope

Purchase flow, receipt fulfilment, token persistence, snapshot restore, hand
generation, exploit prevention, and the pending-run state machine — all Codex.

Board and HUD redesign — #98 phases 3 and 4, separate work. This panel should
be built from current tokens and will inherit those changes for free.
