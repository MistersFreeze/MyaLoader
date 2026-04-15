# Mya Universal — contributor context

## Load order (hub / `init.lua`)

1. **`config.lua`** — compiled and executed; must return a table of default numeric/color keys.
2. **`getgenv().MYA_UNIVERSAL_CONFIG`** — shallow-merged on top of defaults; result stored as **`_G.MYA_UNIVERSAL_CONFIG`** before the runtime bundle runs.
3. **`runtime.lua`** — must return **`function(env)`** with `env.base` (folder URL) and `env.fetch` (HTTP or `readfile`). It concatenates fragments under `runtime/` and `loadstring`s a single bundle (shared scope, order matters).
4. **`gui.lua`** — expects **`_G.MYA_UNIVERSAL`** (getter/setter API) to exist; builds the UI and **`_G.MYA_UNIVERSAL_SYNC_UI`**.

## Runtime bundle (`runtime.lua` + `runtime/*.lua`)

Fragments run in one chunk; **locals** are shared across files — do not redeclare the same `local` name in two fragments.

| Order | File | Role |
|------:|------|------|
| 01 | `01_guard_services.lua` | Services, `lp`; early exit if `_G.MYA_UNIVERSAL` already set |
| 02 | `02_state_config.lua` | Merge `_G.MYA_UNIVERSAL_CONFIG`, state, `esp_gui`, `connections`, camera, vis ray params |
| 03 | `03_targeting.lua` | Teammate / visibility checks, `get_best_target`, `bind_pressed` |
| 04 | `04_esp.lua` | ESP highlights |
| 05 | `05_health_bars.lua` | Health bar Drawing API |
| 06 | `06_fov_rings.lua` | FOV ring Drawing + `update_fov_circles` |
| 07 | `07_aim_assist.lua` | `aim_step` |
| 08 | `08_triggerbot.lua` | `triggerbot_step` |
| 09 | `09_silent_aim.lua` | Silent ray hooks; `silent_max_origin_dist`, `silent_min_look_dot` from config |
| 10 | `10_movement.lua` | Fly / noclip / walk / jump; `hook_players` |
| 11 | `11_render_hooks.lua` | `RenderStepped`, character respawn hooks |
| 12 | `12_exports.lua` | `_G.MYA_UNIVERSAL`, `_G.MYA_UNIVERSAL_LOADED`, `_G.unload_mya_universal` |

## Config keys (optional overrides)

See `config.lua`. Common keys: `aim_assist_fov`, `aim_speed`, `silent_fov`, `silent_max_origin_dist`, `silent_min_look_dot`, `silent_require_raycast_params`, `silent_max_ray_distance`, `silent_aim_part` (`Head` / `HumanoidRootPart` / `UpperTorso` / `LowerTorso`), `trigger_fov`, `trigger_delay`, `fly_speed`, `walk_speed`, `jump_power`, `fov_ring_aim`, `fov_ring_silent` (RGB tables).

**Silent aim & game errors:** Redirecting every `Raycast` (including two-argument calls) can confuse client scripts. Defaults require `RaycastParams` and cap ray length. If silent aim stops working in a game, try `silent_require_raycast_params = false`. If UI/voice scripts error on headshots, try `silent_aim_part = "HumanoidRootPart"` or `"UpperTorso"`.

## GUI module map (main tab → sub-bar)

- **Combat** → Aim assist · Silent aim · Triggerbot  
- **Visuals** → ESP · Health · FOV rings  
- **Movement** → Flight · Walk & jump · Noclip  
- **Settings** — no sub-bar (menu hint + unload).

FOV **ring toggles** live under **Visuals → FOV rings**, not under Combat.

## Unload

`_G.unload_mya_universal()` disconnects tracked connections, tears down ESP/Drawing, restores movement, uninstalls silent hooks when possible, clears `_G.MYA_UNIVERSAL` and UI refs.
