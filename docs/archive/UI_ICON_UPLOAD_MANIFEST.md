# UI Icon Upload Manifest

Status: **no icon pack is approved for upload**.

The generated UI PNG packs below were rejected during art direction review. Preserve
them only as comparison references. Do not upload them to Roblox, wire them into
`src/client/ui/UIAssets.luau`, or treat them as production candidates.

## Rejected Packs

| Pack | Local path | Preview |
| --- | --- | --- |
| Early HUD icon pack | `assets/ui/icons/` | `assets/ui/mockups/hud-icon-upload-pack-preview.png` |
| Blocky BedWars-style icon pack | `assets/ui/icons-blocky-bedwars/` | `assets/ui/mockups/blocky-bedwars-icon-pack-preview.png` |

## Current UIAssets State

`src/client/ui/UIAssets.luau` intentionally keeps all IDs blank until a complete
HUD visual system is approved. The next approved direction should define layout,
panels, typography, icon style, button states, spacing, colors, depth, and
responsive behavior before any individual images are uploaded.

## Deprecated Upload List

| UIAssets key | Local PNG |
| --- | --- |
| `Play` | `assets/ui/icons-blocky-bedwars/play.png` |
| `Shop` | `assets/ui/icons-blocky-bedwars/shop.png` |
| `Quests` | `assets/ui/icons-blocky-bedwars/quests.png` |
| `Settings` | `assets/ui/icons-blocky-bedwars/settings.png` |
| `Coins` | `assets/ui/icons-blocky-bedwars/coins.png` |
| `Wins` | `assets/ui/icons-blocky-bedwars/wins.png` |
| `StoryStars` | `assets/ui/icons-blocky-bedwars/story-stars.png` |

## Safety Notes

- These rejected icons are local project-generated PNGs and contain no scripts.
- Keep them out of production UI until replaced by an approved complete visual system.
- Upload only future approved, project-owned PNGs, not random free model scripts.
- Keep the existing server-authoritative systems for rewards, purchases, currency, and progression.
