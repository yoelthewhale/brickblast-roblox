# UI Icon Upload Manifest

Status: **obsolete and removed from the repository**.

The generated UI PNG packs below were rejected during art direction review and
were removed during the 2026-08-22 asset cleanup. Do not regenerate, upload,
wire, or treat them as production candidates.

## Rejected Packs

| Pack | Former local files | Preview |
| --- | --- | --- |
| Early HUD icon pack | removed during 2026-08-22 cleanup | removed during 2026-08-22 cleanup |
| Blocky BedWars-style icon pack | removed during 2026-08-22 cleanup | removed during 2026-08-22 cleanup |

## Current Production Asset State

The approved production package is `assets/ui/bubblegum-production/`, with real
Roblox image IDs centralized through `src/client/ui/BubblegumAssets.luau`.

## Deprecated Upload List

| UIAssets key | Local PNG |
| --- | --- |
| `Play` | removed rejected PNG |
| `Shop` | removed rejected PNG |
| `Quests` | removed rejected PNG |
| `Settings` | removed rejected PNG |
| `Coins` | removed rejected PNG |
| `Wins` | removed rejected PNG |
| `StoryStars` | removed rejected PNG |

## Safety Notes

- These rejected icons were local project-generated PNGs and contained no scripts.
- Keep the removed packs out of production UI.
- Upload only approved, project-owned PNGs, not random free model scripts.
- Keep the existing server-authoritative systems for rewards, purchases, currency, and progression.
