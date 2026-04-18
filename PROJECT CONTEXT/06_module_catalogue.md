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

## `games/_template.lua`

- **Purpose:** Copy starter for new modules (not loaded unless you register it in config).
- Shows **`ctx.notify`**, **`ctx.uiFactory(theme)`**, and a pattern for storing **`_connections`** to disconnect in **`unmount`**.

## Config snapshot

Update **`06_module_catalogue.md`** when you add or remove supported games so readers stay aligned with **`config.lua`**.
