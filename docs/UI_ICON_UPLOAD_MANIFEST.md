# UI Icon Upload Manifest

Chosen direction: **B Blocky BedWars / blocky competitive**.

Upload these PNGs to Roblox Creator Dashboard or Studio Asset Manager as images.
After each upload, copy the resulting `rbxassetid://...` value into `src/client/ui/UIAssets.luau`.

| UIAssets key | Local PNG |
| --- | --- |
| `Play` | `assets/ui/icons-blocky-bedwars/play.png` |
| `Shop` | `assets/ui/icons-blocky-bedwars/shop.png` |
| `Quests` | `assets/ui/icons-blocky-bedwars/quests.png` |
| `Settings` | `assets/ui/icons-blocky-bedwars/settings.png` |
| `Coins` | `assets/ui/icons-blocky-bedwars/coins.png` |
| `Wins` | `assets/ui/icons-blocky-bedwars/wins.png` |
| `StoryStars` | `assets/ui/icons-blocky-bedwars/story-stars.png` |

Preview sheet:

- `assets/ui/mockups/blocky-bedwars-icon-pack-preview.png`

## Upload Steps

1. Open Roblox Studio on the current local build.
2. Open `View > Asset Manager`.
3. Use bulk import or upload each PNG from `assets/ui/icons-blocky-bedwars`.
4. Copy each created image asset ID.
5. Paste the IDs into `src/client/ui/UIAssets.luau`.
6. Run `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-DayXX.rbxl`.

## Safety Notes

- These icons are local project-generated PNGs and contain no scripts.
- Upload only the PNGs, not any random free model scripts.
- Keep the existing server-authoritative systems for rewards, purchases, currency, and progression.
