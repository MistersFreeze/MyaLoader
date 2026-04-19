# Project Delta module (`games/ProjectDelta_7353845952/`)

Same script for **PlaceIds `7353845952`** and **`7336302630`** (see root `config.lua` `SUPPORTED_GAMES`).

## Load order

1. **`init.lua`** — sets `MYA_FETCH`, `MYA_REPO_BASE`, merges `getgenv().MYA_PROJECT_DELTA_CONFIG` → `_G.MYA_PROJECT_DELTA_CONFIG`, loads `runtime.lua` bundle then `gui.lua`.
2. **`runtime.lua`** — concatenates `runtime/*.lua` in order (shared chunk scope), like Mya Universal.
3. **`gui.lua`** — `lib/mya_game_ui.lua` shell; uses `_G.MYA_PROJECT_DELTA` and `_G.MYA_PROJECT_DELTA_SYNC_UI`.

## Performance notes

- World ESP uses **one** `GetDescendants()` per refresh (**~2.5s**, **deferred** off `RenderStepped` so scans don’t hitch the frame loop). Loose `BasePart` pass skips landmine/trap checks on **huge** parts (`Size.Magnitude > 400`) to avoid work on map geometry; extraction still checks any size. Toggles call **`invalidate_world_pool()`** so turning a category off clears the pool immediately; **render** also filters by current toggles so labels hide the same frame.
- Player **body visibility** ESP raycasts run on **half** the frames when per-part colors are enabled.
- **Distance + name** text use a **combined** player loop when both are enabled.
- FOV rings use **32** segments instead of 64.

## Runtime fragments (excerpt)

| Order | File | Role |
|------|------|------|
| … | `state_config.lua` | Config merge, ESP gui, toggles incl. world ESP + distances |
| … | `movement.lua` | Stubs only (no movement features in this game module) |
| … | `world_fullbright.lua` | Lighting fullbright save/restore |
| … | `world_esp_scan.lua` | Workspace scan / classify NPC · crate · corpse · vehicle · landmine · trap |
| … | `world_esp_labels.lua` | Drawing.Text pool for world labels |
| … | `world_esp_render.lua` | `update_world_esp`, `world_esp_unload` |
| … | `render_hooks.lua` | `RenderStepped`: player ESP + `update_world_esp` |
| … | `exports.lua` | `_G.MYA_PROJECT_DELTA`, `get_config` / `apply_config`, unload |

## Configs

JSON files under workspace folder **`mya_project_delta_configs`** when `writefile` / `readfile` / `listfiles` exist.

## Unload

`_G.unload_mya_project_delta()` tears down connections, ESP, world ESP, fullbright restore, UI.
