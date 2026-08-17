# Day43 UI Control Audit

## Scope

This audit covers visible player-facing `GuiButton` controls in the Hub HUD, Solo full-screen interface, leaderboard/actions area, developer interface, Shop, Inventory/Cosmetics, Settings, and Results flow.

Disabled Battle, Story, and Custom Lab systems remain out of scope for normal players in this checkpoint.

## Hub HUD

| Instance | Visible text/icon | Intended action | Callback or remote | Day43 status |
| --- | --- | --- | --- | --- |
| `RightArcadeNav.playButton` | `PLAY` | Start Solo from the Hub | `HUDController.callbacks.play` -> `Queue:FireServer("Solo")` through client debounce | Working |
| `RightArcadeNav.shopButton` | `SHOP` | Open Shop | `HUDController.callbacks.shop` -> `ShopPanel:Show()` | Working; closes other major panels first |
| `RightArcadeNav.inventoryButton` | `INVENTORY` | Open cosmetics inventory | `HUDController.callbacks.inventory` -> `CosmeticPanel:Show()` | Working; closes other major panels first |
| `RightArcadeNav.settingsButton` | `SETTINGS` | Open supported settings | `HUDController.callbacks.settings` -> side settings menu | Repaired; now applies Motion, Sound, and UI Size |
| `LeftArcadeNav.rewardsButton` | `QUESTS SOON` | Explain unfinished Quests state | `HUDController.callbacks.rewards` -> `MenuController:OpenInfoPanel` | Repaired label; clearly Coming Soon |
| `TopQueueBanner.CancelQueue` | `LEAVE` | Leave Battle queue | Hidden because Battle is disabled | Not player-visible |

## Hub Panel

The compact `HomePanel` exists for legacy Hub affordances but Day41/Day42 keep it hidden through `setHubPanelVisible(false, false)`.

| Instance | Visible text/icon | Intended action | Callback or remote | Day43 status |
| --- | --- | --- | --- | --- |
| `logoButton` | `BB` | Reopen compact Hub panel | Hidden | Not player-visible |
| `closeButton` | `X` | Close compact Hub panel | `callbacks.close` | Hidden with panel |
| `guideButton` | `Guide` | Show tutorial | `callbacks.guide` | Hidden with panel |
| `battleButton` | `Play Solo` in solo-only config | Start Solo | `callbacks.battle` -> `Queue:FireServer("Solo")` through debounce | Hidden with panel; no disabled Battle label |
| `storyButton` | `Story Mode` | Start Story | Hidden when Story disabled | Repaired; disabled mode not exposed |
| `shopButton` | `Shop & Closet` | Open Shop | `callbacks.shop` -> `ShopPanel:Show()` | Hidden with panel |
| settings buttons | Motion/UI Size/Pieces/Board/Sound | Apply supported settings | local settings callbacks -> `Settings:FireServer("Update")` | Hidden with panel |

## Solo Interface

| Instance | Visible text/icon | Intended action | Callback or remote | Day43 status |
| --- | --- | --- | --- | --- |
| `WorkspaceDragHandle` | `SOLO PUZZLE` | Header drag affordance from legacy windowed layout | `ArcadeUI.AttachWorkspaceInteraction` | Still present as title; full-screen layout clamps movement to screen |
| `WorkspaceSettingsButton` | `SET` | Open supported settings | delegates to `HUDController.callbacks.settings` | Repaired; now opens working settings panel |
| `WorkspaceHelpButton` | `?` | Show tutorial | sets tutorial visible | Working |
| `WorkspaceCloseButton` | `X` | Return to Hub | `Queue:FireServer("LeaveBattle")` through debounce | Repaired naming/debounce; same flow as Return Hub |
| `BoardGridContainer.1_1` through `8_8` | blank cells | Place selected piece | `Place:FireServer(slot, x, y)` after local legality check and debounce | Working; exactly 64 cell buttons |
| `HandSlot1` through `HandSlot3` | piece preview/label | Select piece | local selected-slot callback | Working |
| `WorkspaceResizeHandle` | `Resize` | Obsolete window resize | Hidden, inactive, unselectable | Repaired; no longer player-facing |

## Leaderboard And Actions

| Instance | Visible text/icon | Intended action | Callback or remote | Day43 status |
| --- | --- | --- | --- | --- |
| `ReturnHubButton` | `Return Hub` | Return to Hub | `Queue:FireServer("LeaveBattle")` through debounce | Repaired naming/debounce |
| `PlayAgainButton` | `Play Again` | Start next run after result/game over | `Queue:FireServer("PlayAgain")` through debounce | Working |
| `RotatePieceButton` | `Rotate` | Custom Lab rotate | Hidden because Custom Lab is disabled | Not player-visible |
| `RerollPieceButton` | `Reroll` | Custom Lab reroll | Hidden because Custom Lab is disabled | Not player-visible |

## Developer Interface

Developer controls remain authorized-only. They are player-facing only for allowlisted developer accounts and preserve record suppression.

| Instance | Visible text/icon | Intended action | Callback or remote | Day43 status |
| --- | --- | --- | --- | --- |
| `DeveloperToolsButton` | `DEV` | Open/close developer panel | local toggle + `DevCommand:InvokeServer({ action = "Diagnostics" })` | Working; authorized-only |
| `DeveloperPanelCloseButton` | `X` | Close developer panel | local close | Working |
| Stage section buttons | `Set Stage 3`, `+20 Stage`, `Advance Stage`, `Combo 5` | Controlled dev setup | `DevCommand:InvokeServer` | Working; marks test run |
| Board Setup buttons | `Empty`, `Near Line`, `Perfect Setup`, `Crowded`, `Single Only`, `No Move` | Controlled dev board states | `DevCommand:InvokeServer` | Working; marks test run |
| Hand Setup buttons | `Smart Hand`, `Hand: small` | Controlled dev hand states | `DevCommand:InvokeServer` | Working; marks test run |
| Run Controls buttons | `Clear Board`, `Reset Run` | Destructive dev reset/clear | `DevCommand:InvokeServer` | Working; records disabled |
| Diagnostics button | `Diagnostics` | Refresh read-only diagnostics | `DevCommand:InvokeServer` | Working; does not mark test run |

## Shop

| Instance | Visible text/icon | Intended action | Callback or remote | Day43 status |
| --- | --- | --- | --- | --- |
| `ShopDim` | blank overlay | Close modal by outside click | `ShopPanel:Hide()` | Working; inactive when hidden |
| `closeButton` | `X` | Close Shop | `ShopPanel:Hide()` | Working |
| category tabs | `Featured`, `Passes`, `Cosmetics`, `Currency` | Switch category | local category change + analytics track | Working |
| item `Gift` buttons | `Gift` | Future gifting | local Coming Soon message | Working as explicit future state |
| item action buttons | `Buy`, `Equip`, `Owned`, `Locked`, `Unavailable`, etc. | Purchase/equip/show blocked reason | `Shop:FireServer(...)` or local message | Working/server-authoritative |
| item preview buttons | `Preview` | Preview cosmetic | local preview callback + analytics track | Working |

## Inventory/Cosmetics

| Instance | Visible text/icon | Intended action | Callback or remote | Day43 status |
| --- | --- | --- | --- | --- |
| `closeButton` | `X` | Close inventory | `CosmeticPanel:Hide()` | Working |
| piece cards | skin names | Equip unlocked piece skin or show lock reason | local settings update -> `Settings:FireServer("Update")` | Working |
| board cards | board names | Equip unlocked board skin or show lock reason | local settings update -> `Settings:FireServer("Update")` | Working |

## Settings

| Instance | Visible text/icon | Intended action | Callback or remote | Day43 status |
| --- | --- | --- | --- | --- |
| side-menu close | `X` | Close settings | `MenuController:Close()` | Working |
| side-menu dim | blank overlay | Close settings | `MenuController:Close()` | Working; inactive when hidden |
| Motion button | `Motion: Full/Reduced` | Toggle reduced motion | local state + `Settings:FireServer("Update")` | Repaired |
| Sound button | `Sound: 65%/35%/Off` | Cycle sound volume | local state + `Settings:FireServer("Update")` | Repaired |
| UI Size button | `UI Size: Auto/Large/Compact` | Cycle UI scale | local state + `Settings:FireServer("Update")` | Repaired |

## Results/Game Over

| Instance | Visible text/icon | Intended action | Callback or remote | Day43 status |
| --- | --- | --- | --- | --- |
| result close | `X` | Dismiss result panel | `ResultPanel:Hide()` | Working |
| result replay | `Play Again` | Replay current/next run | `Queue:FireServer("PlayAgain")` or `Queue:FireServer("Solo")` with debounce | Repaired debounce |

## Choppiness And Input Findings

- Shop and side-menu dim overlays were hidden visually but remained active. Day43 sets them inactive while hidden.
- Multiple major panels could remain open together from Hub callbacks. Day43 closes other major panels before opening Shop, Inventory, Story, or Settings.
- Server-facing Hub/Solo navigation actions had no client debounce. Day43 adds a shared debounce for queue/return/replay requests.
- Board placement had no client debounce, relying only on the server. Day43 adds a small local debounce matching the server placement cadence.
- The obsolete Solo resize handle was still constructed as a player-facing button. Day43 hides it, disables input, and removes it from selection.
- Disabled mode controls were still present in legacy HomePanel and hidden Modes-menu code paths. Day43 gates those paths with `ExperienceConfig`.
- The 64-cell board is built once at startup and not rebuilt during panel navigation.
