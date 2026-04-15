# Mya Universal — contributor context

## Load order (hub / `init.lua`)

1. **`config.lua`** — compiled and executed; must return a table of default numeric/color keys.
2. **`getgenv().MYA_UNIVERSAL_CONFIG`** — shallow-merged on top of defaults; result stored as **`_G.MYA_UNIVERSAL_CONFIG`** before the runtime bundle runs.
3. **`runtime.lua`** — must return **`function(env)`** with `env.base` (folder URL) and `env.fetch` (HTTP or `readfile`). It concatenates fragments under `runtime/` and `loadstring`s a single bundle (shared scope, order matters).
4. **`gui.lua`** — expects **`_G.MYA_UNIVERSAL`** (getter/setter API) to exist; builds the UI and **`_G.MYA_UNIVERSAL_SYNC_UI`**.
5. **Configs** — **`_G.get_config`** returns a JSON-serializable settings table; **`_G.apply_config(cfg)`** applies it and refreshes the UI. Files live under workspace folder **`mya_universal_configs`** (`*.json`) when the executor supports `writefile` / `readfile` / `listfiles`.

## Runtime bundle (`runtime.lua` + `runtime/*.lua`)

Fragments run in one chunk; **locals** are shared across files — do not redeclare the same `local` name in two fragments.

**Naming:** Files use **descriptive snake_case names** (no numeric prefixes). **Load order is not implied by filenames** — it is defined only by the `order` table in **`runtime.lua`**. When adding or splitting fragments, insert the path in that list in the correct place.

| Load order | File | Role |
|:----------:|------|------|
| 1 | `guard_services.lua` | Services, `lp`; early exit if `_G.MYA_UNIVERSAL` already set |
| 2 | `state_config.lua` | Merge `_G.MYA_UNIVERSAL_CONFIG`, state, `esp_gui`, `connections`, camera, vis ray params |
| 3 | `targeting.lua` | Teammate / visibility checks, `get_best_target`, `get_silent_aim_world`, `bind_pressed` |
| 4 | `esp.lua` | ESP highlights |
| 5 | `esp_distance.lua` | Distance labels (Drawing text) |
| 6 | `health_bars.lua` | Health bar Drawing API |
| 7 | `fov_rings.lua` | FOV ring Drawing + `update_fov_circles` |
| 8 | `aim_assist.lua` | `aim_step` |
| 9 | `triggerbot.lua` | `triggerbot_step` |
| 10 | `silent_aim.lua` | Silent ray hooks (Raycast hook preferred over `__namecall` when possible). |
| 11 | `movement.lua` | Fly / noclip / walk & jump overrides; `hook_players` |
| 12 | `render_hooks.lua` | `RenderStepped`, character respawn hooks |
| 13 | `exports.lua` | `_G.MYA_UNIVERSAL`, `get_config` / `apply_config`, unload |

## Config keys (optional overrides)

See `config.lua`. Common keys: `aim_assist_fov`, `aim_speed`, `silent_fov`, `silent_max_origin_dist`, `silent_min_look_dot`, `silent_require_raycast_params`, `silent_max_ray_distance`, `silent_aim_part` (`Head` / `HumanoidRootPart` / `UpperTorso` / `LowerTorso`), `trigger_fov`, `trigger_delay`, `fly_speed`, `walk_speed`, `jump_power`, `fov_ring_aim`, `fov_ring_silent` (RGB tables).

**Silent aim & game errors:** Redirecting every `Raycast` (including two-argument calls) can confuse client scripts. Defaults require `RaycastParams` and cap ray length. If silent aim stops working in a game, try `silent_require_raycast_params = false`. If UI/voice scripts error on headshots, try `silent_aim_part = "HumanoidRootPart"` or `"UpperTorso"`.

## GUI module map (main tab → sub-bar)

- **Combat** → Aim assist (incl. aim FOV + **show aim FOV ring**) · Silent aim (incl. silent FOV + **show silent FOV ring**) · Triggerbot  
- **Visuals** → **ESP** (highlights, **team check**, health bars, **distance text**)  
- **Movement** → Flight · Walk & jump (walk/jump **override** toggles + sliders) · Noclip  
- **Configs** — list/load/save/delete JSON configs (`mya_universal_configs`).  
- **Settings** — menu hint + unload.

## Unload

`_G.unload_mya_universal()` disconnects tracked connections, tears down ESP/Drawing, restores movement, uninstalls silent hooks when possible, clears `_G.MYA_UNIVERSAL` and UI refs.
