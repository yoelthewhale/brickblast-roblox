# Monetization Setup

This project intentionally ships with every marketplace ID set to `0`.
Do not replace these with random IDs. `0` means unavailable and prevents purchase prompts.

## Central ID Location

Edit marketplace IDs only in `src/shared/game/Config.luau`:

- `Config.Monetization.GamePasses[].gamePassId`
- `Config.Monetization.DeveloperProducts[].productId`

Current placeholders:

- `VIP_PASS`: VIP Pass
- `DELUXE_COSMETICS_PASS`: Deluxe Cosmetics Pass
- `EXTRA_PRESET_SLOTS_PASS`: Extra Preset Slots Pass
- `SUPPORTER_PASS`: Supporter Pass
- `COINS_SMALL`: Small Coin Pack
- `COINS_MEDIUM`: Medium Coin Pack
- `COINS_LARGE`: Large Coin Pack

## Creator Dashboard Steps

1. Open Roblox Creator Dashboard.
2. Select the Block Blast Battle experience.
3. Open Monetization.
4. Create each game pass:
   - VIP Pass
   - Deluxe Cosmetics Pass
   - Extra Preset Slots Pass
   - Supporter Pass
5. Copy each game pass ID into `Config.Monetization.GamePasses`.
6. Create developer products for currency packs only if you are ready to sell currency:
   - Small Coin Pack
   - Medium Coin Pack
   - Large Coin Pack
7. Copy each developer product ID into `Config.Monetization.DeveloperProducts`.
8. Publish the place and run a Studio purchase test with test accounts.
9. Verify that owned passes show as owned after purchase cancellation/success flows.
10. Verify `ProcessReceipt` grants currency once and only from the server.

## Security Rules

- Never grant coins, XP, cosmetics, or ownership from the client.
- The client only requests a server-approved purchase prompt.
- The server validates the item identifier and marketplace ID before allowing a prompt.
- Game pass ownership uses `UserOwnsGamePassAsync` with short-lived cache and post-purchase refresh.
- Developer products are fulfilled only inside `MarketplaceService.ProcessReceipt`.
- Receipt IDs are tracked in memory and persisted through `BlockBlastReceiptsV1` when DataStore is available.
- Keep every ID at `0` until the Creator Dashboard item exists.
- Do not add production test overrides.

## Current Limitation

Real purchase prompts cannot be fully tested until valid Creator Dashboard IDs are added and the place is tested through Roblox Studio or a published test experience.
