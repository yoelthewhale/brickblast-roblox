# Studio Test Checklist

Do not mark these complete until verified in Roblox Studio or a published test experience.

## Player Data And Migration

- Fresh player joins with Rainbow Pieces, Auto Board, Spark Clear, and Rookie Title owned/equipped.
- Existing player with old `settings.pieceSkin` and `settings.boardSkin` migrates into `profile.cosmetics.equipped`.
- Invalid saved cosmetic IDs are ignored and default cosmetics are equipped.
- Removed or renamed cosmetic IDs do not break profile load.
- Equipped cosmetics persist after leaving and rejoining.

## Shop And Inventory

- Repeated shop open/close does not duplicate UI or leave preview visuals active.
- Cosmetics tab loads server-owned catalog data, not client-invented ownership.
- Previewing a piece or board cosmetic changes visuals locally without saving or granting.
- Closing the shop restores the actual equipped cosmetics.
- Buying Sugar Board with enough coins deducts exactly 150 coins, owns the item, and can equip it.
- Buying Ripple Clear with enough coins deducts exactly 100 coins, owns the item, and can equip it.
- Insufficient currency shows a clear failure and does not change ownership.
- Duplicate rapid purchase requests do not double-deduct coins.
- Equip requests for unowned, malformed, or mismatched IDs are rejected by the server.
- Currency balance refreshes after purchases and developer-product receipt fulfillment.

## Marketplace

- Placeholder `0` IDs never open purchase prompts.
- Non-owned game passes show unavailable until Creator Dashboard IDs are added.
- Purchase cancellation clears prompt locks and returns the shop to usable state.
- Successful game pass purchase refreshes ownership state.
- Developer-product receipt retry does not grant coins twice after repeated `ProcessReceipt`.
- Developer-product receipt retry after server restart sees `profile.fulfilledPurchaseIds` and no-ops safely.
- Unknown developer product IDs return `NotProcessedYet`.

## Input And Layout

- Shop cards remain readable on phone, tablet, and desktop Studio emulation.
- Touch targets are comfortable on mobile.
- Gamepad focus enters the home panel and shop close button correctly.
- Keyboard/gamepad activation can buy/equip/preview without mouse-only dependency.
- Safe-area behavior avoids clipping on small screens.
- Phone-sized viewports use the stacked Solo layout: stats strip, full-width board, tray, bottom action bar, and no leaderboard during a run.
- Starting a Solo run on a phone locks the screen to portrait, and rotating the device mid-run does nothing.
- Returning to the hub releases the portrait lock, and the device rotates freely again.
- Tablets and desktops are never orientation-locked, in the hub or in a run.

## Gameplay Application

- Equipped piece skin controls new hand colors.
- Equipped board skin controls board empty and border colors.
- Equipped Ripple Clear changes line-clear feedback without changing scoring or hitboxes.
- Equipped player title appears in the in-run progression line.
- Reduced-motion setting still suppresses motion-heavy feedback.
- Two-player battle state does not reveal unnecessary private inventory data.
