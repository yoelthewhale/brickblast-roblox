# BrickBlast Bubblegum Toybox Asset Pack

Production-oriented Roblox UI artwork. Keep native Roblox UI for cards, buttons, board cells, tray slots, text, and progress bars.

## Roblox integration
- Icons/decor/reward crates: `ImageLabel`/`ImageButton`, `ScaleType = Fit`.
- Runtime particles: white/neutral source images; tint with `ImageColor3`, `ParticleEmitter.Color`, or equivalent.
- `ui/shadow_soft_9slice.png`: use `ScaleType = Slice`; start with `SliceCenter = Rect.new(64, 64, 192, 192)` on the 256x256 source. Keep enough surrounding size for blur.
- Do not parent decorative images into `BoardGridContainer`; the board must remain exactly 64 cells.
- Preserve Bubblegum Toybox dynamic stage/energy coloring in native UI; these assets should support it, not replace it.

See `manifest.json` for per-file usage.
