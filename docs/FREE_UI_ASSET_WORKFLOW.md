# Free UI Asset Workflow

This project is using the free route for higher-quality UI visuals.

## Recommended Free Pipeline

1. Design or recreate the UI in Figma.
2. Use the free RoImport Figma-to-Roblox workflow to bring frames into Roblox Studio.
3. Upload project-owned PNG icons through Creator Dashboard.
4. Paste the resulting `rbxassetid://...` values into `src/client/ui/UIAssets.luau`.
5. Keep the game logic in existing client/server modules. Imported UI should provide visuals only.

## Why Not Paste A Screenshot

- A screenshot cannot react to queue state, screen size, ownership state, or settings.
- It cannot support touch/gamepad focus properly.
- It cannot safely call the existing server-authoritative remotes.
- It will blur or stretch across device sizes.

## Current Icon Slots

Update these keys in `src/client/ui/UIAssets.luau` after upload:

- `Play`
- `Shop`
- `Quests`
- `Settings`
- `Coins`
- `Wins`
- `StoryStars`

Until an ID is added, the HUD uses native Roblox text badges as a safe fallback.

## Safe Import Rules

- Import free Creator Store GUI models only into a quarantine test place first.
- Review every `Script`, `LocalScript`, `ModuleScript`, plugin, remote, sound, and inserted service object.
- Delete third-party scripts unless we intentionally port a small inspected helper.
- Never keep code that grants coins, wins, XP, items, ownership, gamepasses, developer products, or DataStore writes.
- Never publish a place directly after importing an unreviewed model.
- Keep all purchase, reward, inventory, and save logic inside our repository-controlled server systems.

## Good Free Options To Try

- Roblox UI Kit for Figma: useful for layout planning.
- RoImport: useful for converting Figma frames into Roblox UI objects.
- Free Creator Store GUI models: useful only as visual reference or quarantined extractable art.

## Next Implementation Step

Create/upload the seven icon PNGs listed above, then replace the placeholders in `UIAssets.luau`.
After that, rebuild the place and verify the spawn HUD in Studio on desktop and phone landscape.
