# Mya Universal — contributor context

## Load order (hub / `init.lua`)

1. **`config.lua`** — compiled and executed; must return a table of default numeric/color keys.
2. **`getgenv().MYA_UNIVERSAL_CONFIG`** — shallow-merged on top of defaults; result stored as **`_G.MYA_UNIVERSAL_CONFIG`** before the runtime bundle runs.
3. **`runtime.lua`** — must return **`function(env)`** with `env.base` (folder URL) and `env.fetch` (HTTP or `readfile`). It concatenates fragments under `runtime/` and `loadstring`s a single bundle (shared scope, order matters).
4. **`init.lua`** sets **`_G.MYA_REPO_BASE`** (normalized repo root from `ctx.baseUrl`) and **`_G.MYA_FETCH`** = `fetch` so **`gui.lua`** can HttpGet **`lib/mya_game_ui.lua`** from the same host as the hub.
5. **`gui.lua`** — loads **`lib/mya_game_ui.lua`** (`defaultTheme`, `createHubShell`, `createNotifyStack`), expects **`_G.MYA_UNIVERSAL`** (getter/setter API) after runtime; builds the UI and **`_G.MYA_UNIVERSAL_SYNC_UI`**.
6. **Configs** — **`_G.get_config`** returns a JSON-serializable settings table; **`_G.apply_config(cfg)`** applies it and refreshes the UI. Files live under workspace folder **`mya_universal_configs`** (`*.json`) when the executor supports `writefile` / `readfile` / `listfiles`.

## Runtime bundle (`runtime.lua` + `runtime/*.lua`)

Fragments run in one chunk; **locals** are shared across files — do not redeclare the same `local` name in two fragments.

**Naming:** Files use **descriptive snake_case names** (no numeric prefixes). **Load order is not implied by filenames** — it is defined only by the `order` table in **`runtime.lua`**. When adding or splitting fragments, insert the path in that list in the correct place.

| Load order | File | Role |
|:----------:|------|------|
| 1 | `guard_services.lua` | Services, `lp`; early exit if `_G.MYA_UNIVERSAL` already set |
| 2 | `state_config.lua` | Merge `_G.MYA_UNIVERSAL_CONFIG`, state, `esp_gui`, `connections`, camera, vis ray params |
| 3 | `targeting.lua` | Teammate / visibility checks, `get_best_target`, `bind_pressed` |
| 4 | `esp.lua` | ESP highlights |
| 5 | `esp_distance.lua` | Distance labels (Drawing text) |
| 6 | `health_bars.lua` | Health bar Drawing API |
| 7 | `fov_rings.lua` | Aim FOV ring Drawing + `update_fov_circles` |
| 8 | `aim_assist.lua` | `aim_step` |
| 9 | `triggerbot.lua` | `triggerbot_step` |
| 10 | `movement.lua` | Fly / noclip / walk & jump overrides; `hook_players` |
| 11 | `render_hooks.lua` | `RenderStepped`, character respawn hooks |
| 12 | `exports.lua` | `_G.MYA_UNIVERSAL`, `get_config` / `apply_config`, unload |

## Config keys (optional overrides)

See `config.lua`. Common keys: `aim_assist_fov`, `aim_speed`, `aim_fov_follow_cursor`, `trigger_fov`, `trigger_delay`, `fly_speed`, `walk_speed`, `jump_power`, `fov_ring_aim` (RGB table), `esp_names_on`, etc.

## GUI module map (main tab → sub-bar)

- **Combat** → Aim assist (incl. aim FOV + **show aim FOV ring**) · Triggerbot  
- **Visuals** → **ESP** (highlights, **team check**, health bars, **distance text**, **player names**)  
- **Movement** → Flight · Walk & jump (walk/jump **override** toggles + sliders) · Noclip  
- **Configs** — list/load/save/delete JSON configs (`mya_universal_configs`).  
- **Settings** — menu hint + unload.

## Unload

`_G.unload_mya_universal()` disconnects tracked connections, tears down ESP/Drawing, restores movement, clears `_G.MYA_UNIVERSAL` and UI refs.
