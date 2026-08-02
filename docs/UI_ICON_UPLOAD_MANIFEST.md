# UI Icon Upload Manifest

Upload these PNGs to Roblox Creator Dashboard or Studio Asset Manager as images.
After each upload, copy the resulting `rbxassetid://...` value into `src/client/ui/UIAssets.luau`.

| UIAssets key | Local PNG |
| --- | --- |
| `Play` | `assets/ui/icons/play.png` |
| `Shop` | `assets/ui/icons/shop.png` |
| `Quests` | `assets/ui/icons/quests.png` |
| `Settings` | `assets/ui/icons/settings.png` |
| `Coins` | `assets/ui/icons/coins.png` |
| `Wins` | `assets/ui/icons/wins.png` |
| `StoryStars` | `assets/ui/icons/story-stars.png` |

Preview sheet:

- `assets/ui/mockups/hud-icon-upload-pack-preview.png`

## Upload Steps

1. Open Roblox Studio on the current local build.
2. Open `View > Asset Manager`.
3. Use bulk import or upload each PNG from `assets/ui/icons`.
4. Copy each created image asset ID.
5. Paste the IDs into `src/client/ui/UIAssets.luau`.
6. Run `.\tools\rojo.exe build default.project.json --output BlockBlastBattle-DayXX.rbxl`.

## Safety Notes

- These icons are local project-generated PNGs and contain no scripts.
- Upload only the PNGs, not any random free model scripts.
- Keep the existing server-authoritative systems for rewards, purchases, currency, and progression.
