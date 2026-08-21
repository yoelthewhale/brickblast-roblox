# Bubblegum Toybox Roblox Asset Upload Guide

The production PNG package is extracted at:

`assets/ui/bubblegum-production/`

Roblox UI cannot display local PNG files directly from this Rojo checkout. Upload each PNG below to Roblox, then paste the returned `rbxassetid://...` value into:

`src/client/ui/BubblegumAssets.luau`

Keep every ID centralized in `BubblegumAssets.Images`. Do not paste IDs into individual UI files.

## Upload Checklist

| Registry key | Local file | Intended use | Runtime tint | ScaleType | SliceCenter |
| --- | --- | --- | --- | --- | --- |
| `Coin` | `assets/ui/bubblegum-production/icons/icon_coin.png` | Coins/currency icon | No | `Fit` |  |
| `XP` | `assets/ui/bubblegum-production/icons/icon_xp.png` | XP icon | No | `Fit` |  |
| `BestScore` | `assets/ui/bubblegum-production/icons/icon_best.png` | Best-score badge | No | `Fit` |  |
| `Trophy` | `assets/ui/bubblegum-production/icons/icon_trophy.png` | Trophy/rank stat | No | `Fit` |  |
| `Stage` | `assets/ui/bubblegum-production/icons/icon_stage.png` | Stage/progression icon | No | `Fit` |  |
| `MedalFirst` | `assets/ui/bubblegum-production/medals/medal_first.png` | 1st place medal | No | `Fit` |  |
| `MedalSecond` | `assets/ui/bubblegum-production/medals/medal_second.png` | 2nd place medal | No | `Fit` |  |
| `MedalThird` | `assets/ui/bubblegum-production/medals/medal_third.png` | 3rd place medal | No | `Fit` |  |
| `RewardCrateClosed` | `assets/ui/bubblegum-production/rewards/crate_reward_closed.png` | Closed reward crate | No | `Fit` |  |
| `RewardCrateOpen` | `assets/ui/bubblegum-production/rewards/crate_reward_open.png` | Opened reward crate | No | `Fit` |  |
| `SparkleParticle` | `assets/ui/bubblegum-production/particles/sparkle_particle.png` | Sparkle/burst particle | Yes | `Fit` |  |
| `ConfettiRect` | `assets/ui/bubblegum-production/particles/confetti_rect.png` | Confetti particle | Yes | `Fit` |  |
| `ConfettiDot` | `assets/ui/bubblegum-production/particles/confetti_dot.png` | Confetti particle | Yes | `Fit` |  |
| `ConfettiStar` | `assets/ui/bubblegum-production/particles/confetti_star.png` | Confetti particle | Yes | `Fit` |  |
| `ConfettiSquiggle` | `assets/ui/bubblegum-production/particles/confetti_squiggle.png` | Confetti particle | Yes | `Fit` |  |
| `ShadowSoft` | `assets/ui/bubblegum-production/ui/shadow_soft_9slice.png` | Reusable soft card/panel shadow | Yes | `Slice` | `Rect.new(64, 64, 192, 192)` |
| `CandyFlourishCorner` | `assets/ui/bubblegum-production/decor/candy_flourish_corner.png` | Decorative corner flourish | No | `Fit` |  |
| `LollipopMark` | `assets/ui/bubblegum-production/decor/lollipop_mark.png` | Decorative lollipop mark | No | `Fit` |  |

## Paste Format

Use this format in `BubblegumAssets.Images`:

```lua
Coin = "rbxassetid://<uploaded-roblox-image-id>",
```

Leave keys blank until that specific asset is uploaded:

```lua
Coin = "",
```

## Notes

- Particle source art is intentionally neutral/white. Let Roblox tint it at runtime.
- Do not runtime-tint medal metals unless design direction changes.
- `ShadowSoft` must use `Enum.ScaleType.Slice` with `Rect.new(64, 64, 192, 192)`; the registry already applies that once an ID is present.
- Do not parent decorative images into `BoardGridContainer`; that grid must remain exactly 64 interactive board cells.
