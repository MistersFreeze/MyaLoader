# Module catalogue

Games live under **`games/`**. **Place-specific** modules are listed in **`config.lua` → `SUPPORTED_GAMES`**.

## `games/example.lua`

- **Purpose:** Minimal demo proving the pipeline works for a PlaceId you add in config.
- **Structure:** Single file; exports `mount` / `unmount` (no-op unmount).

## `games/MyaUniversal/`

- **PlaceId:** None (not in `SUPPORTED_GAMES`).
- **Launch:** Hub sidebar **Universal → Mya Universal** (loads `init.lua` via `Util.loadModuleFromUrl`).
- **Features:** ESP highlights, aim assist, silent aim (Raycast hook), triggerbot, fly, noclip, walk/jump; **Insert** toggles menu.
- **Files:** `init.lua` sets **`MYA_REPO_BASE`** + **`MYA_FETCH`**, then **`runtime.lua`** (bundle under **`runtime/`**) → **`gui.lua`**. **`runtime.lua`** HttpGets **`lib/mya_combat_helpers.lua`** from the repo root and injects it as **`Combat`** for shared team/LOS/hit-part logic. **`gui.lua`** loads **`lib/mya_game_ui.lua`** (`createHubShell`, tabs + sub-tabs, configs/settings).
- **Teardown:** **`_G.unload_mya_universal`**.

## `games/Operation-One_72920620366355/`

- **PlaceId:** `72920620366355` (Operation One).
- **Entry:** `init.lua` (registered in `config.lua`).
- **Pattern:** `init.lua` computes **`base`**, sets **`MYA_REPO_BASE`** + **`MYA_FETCH`**, fetches **`runtime.lua`** (returns a **bundle loader** `function(env)` with `env.fetch` / `env.base`), then **`gui.lua`**. Calls **`_G.MYA_OP1_RUN_UI_SYNC`** if defined.
- **GUI:** **`lib/mya_game_ui.lua`** hub shell (sidebar: Combat / Movement / Visuals / Misc / Configs; Combat–Visuals have sub-pages). Custom cursor + color pickers + config list remain in **`gui.lua`**.
- **Runtime:** Ordered fragments under **`runtime/`** (e.g. `state_visuals_helpers.lua`, `globals_config.lua`, …) concatenated into one chunk.
- **Teardown:** `unmount` → **`_G.unload_mya`**.

## `games/Neighbors_110400717151509/`

- **PlaceIds:** `110400717151509`, `12699642568` (same module in config).
- **Entry:** `init.lua` sets **`MYA_REPO_BASE`** + **`MYA_FETCH`**, fetches bundle **`runtime.lua`** then **`gui.lua`**.
- **GUI:** **`lib/mya_game_ui.lua`** (default window size matches Universal: **540×400**). Tabs: Piano, Visuals, Piano Settings, Misc, **Settings** (unload + hints). Notifications parent to **PlayerGui** (toast `createNotifyStack` option). Rows use theme **`C.panel`** + rounded corners.
- **Piano:** MIDI load/play, speed/position sliders; **queue (next song):** separate path/URL into **`load_midi_into_queue`**, **queue start (0–1)**, **Play queued song** + optional **keybind** (default **F9**) — runtime in **`runtime/piano_engine.lua`** (`play_queued_song`, etc.). Backup single file: **`runtime_monolith.lua`** (keep in sync when changing engine exports).
- **Runtime fragments:** Under **`runtime/`** — **`piano_engine.lua`**, **`visuals.lua`**, **`movement.lua`**, **`targeting.lua`**, **`exports.lua`** (order defined in **`runtime.lua`**).
- **Teardown:** **`_G.unload_mya`**.

## `games/FlexYourFPS_18667984660/`

- **PlaceId:** `18667984660` (Flex Your FPS And Ping).
- **Entry:** `init.lua` (registered in `config.lua`).
- **Pattern:** **`MYA_REPO_BASE`** + **`MYA_FETCH`**, **`runtime.lua`** bundles **`runtime/state.lua`** + **`runtime/flex.lua`**, then **`gui.lua`** (`lib/mya_game_ui.lua`).
- **Features:** Sliders — **FPS × 1–15**, **Ping × 0.1–10**, **Resolution × 0.1–10** (billboard `WxH` text when a matching label exists + **`settings().Rendering.QualityLevel`**); local FPS from **PreRender** counter; ping from **`Player:GetNetworkPing()`** (seconds → ms). Toggle to pause flex; **Insert** menu; **Unload** → **`_G.unload_mya`**.
- **Teardown:** **`_G.unload_mya`**.

## `games/ViolenceDistrict_93978595733734/`

- **PlaceId:** `93978595733734` — Violence District, DbD-style asym horror.
- **Entry:** `init.lua`, registered in `config.lua`. Loads **`gui.lua`** with **`MYA_REPO_BASE`** and **`MYA_FETCH`** like Flex Your FPS.
- **GUI:** **`lib/mya_game_ui.lua`** hub shell. **Visuals:** pink other **Survivors**; **Hooked** and **Knocked** models from **`CollectionService`** using the same rules as dumped **`Highlight-forsurvivor`**; red **killer** from **`Teams.Killer`**; **Generator** models with **`RepairProgress`**-lerped highlight fill plus a **`BillboardGui`** percent label; exits, levers, vaults, pallets; **opened** map doors only after every in-map generator **`RepairProgress`** is **100** or more; trapdoor name scan after **`Remotes.Generator.Escapetime`** when one survivor remains. **Killer** team: optional HUD listing recent **`Remotes.Killers.Killer`** **`CooldownEvent`**, **`ActivatePower`**, **`PowerDoneDeactivating`**, **`Deactivate`**, and **`IdleRefreshEvent`** **`OnClientEvent`** lines. **Assist:** auto skill check via **`VirtualInputManager`**. **Insert** toggles menu; **Unload** → **`_G.unload_mya_vd`**.

## `games/PrisonLife_155615604/`

- **PlaceId:** `155615604` (Prison Life).
- **Entry:** `init.lua` (registered in `config.lua`). Config merge: **`getgenv().MYA_PRISON_LIFE_CONFIG`** (or **`MYA_UNIVERSAL_CONFIG`**) over **`config.lua`** defaults.
- **Pattern:** Same bundle style as Mya Universal — **`runtime.lua`** prepends **`lib/mya_combat_helpers.lua`** as **`Combat`**, concatenates **`runtime/*.lua`**, then **`gui.lua`** (`lib/mya_game_ui.lua`).
- **Game-specific:** Prison Life exposes **`Teams.Inmates`**, **`Teams.Guards`**, **`Teams.Criminals`**. Separate **Prisoner check** toggles (Inmates team) under **Aim assist**, **Silent aim**, and **Visuals → ESP**, independent of team check. Triggerbot follows aim assist targeting. **Movement → Car flight**: bind + speed slider; applies **`BodyVelocity`** to the vehicle model while seated in a **`VehicleSeat`**. Legacy config key **`pl_skip_inmates = true`** still maps all three prisoner checks on when the per-mode keys are omitted.
- **Teardown:** **`_G.unload_mya_universal`**.

## `games/_template.lua`

- **Purpose:** Copy starter for new modules (not loaded unless you register it in config).
- Shows **`ctx.notify`**, **`ctx.uiFactory(theme)`**, and a pattern for storing **`_connections`** to disconnect in **`unmount`**.

## Config snapshot

Update **`06_module_catalogue.md`** when you add or remove supported games so readers stay aligned with **`config.lua`**.

When you add a PlaceId, also add **`hub.lua` → `GAME_DISPLAY_NAMES`** (Games tab labels) and ensure **`loader.lua`** / **`hub.lua`** bootstrap notes in **`PROJECT CONTEXT`** stay accurate (see **`09_workflows.md`**).
