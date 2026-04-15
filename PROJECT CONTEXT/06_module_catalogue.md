# Module catalogue

Games live under **`games/`**. **Place-specific** modules are listed in **`config.lua` → `SUPPORTED_GAMES`**.

## `games/example.lua`

- **Purpose:** Minimal demo proving the pipeline works for a PlaceId you add in config.
- **Structure:** Single file; exports `mount` / `unmount` (no-op unmount).

## `games/MyaUniversal/`

- **PlaceId:** None (not in `SUPPORTED_GAMES`).
- **Launch:** Hub sidebar **Universal → Mya Universal** (loads `init.lua` via `Util.loadModuleFromUrl`).
- **Features:** ESP highlights, aim assist (RMB), fly, noclip, walk speed, jump power; **Insert** toggles menu.
- **Files:** `init.lua` → `runtime.lua` → `gui.lua`; teardown **`_G.unload_mya_universal`**.

## `games/Operation-One_72920620366355/`

- **PlaceId:** `72920620366355` (Operation One).
- **Entry:** `init.lua` (registered in `config.lua`).
- **Pattern:** `init.lua` computes **`base`**, fetches **`runtime.lua`** (returns a **bundle loader** `function(env)` with `env.fetch` / `env.base`), then **`gui.lua`**. Calls **`_G.MYA_OP1_RUN_UI_SYNC`** if defined.
- **Runtime:** Ordered fragments under **`runtime/`** (e.g. `state_visuals_helpers.lua`, `globals_config.lua`, …) concatenated into one chunk.
- **Teardown:** `unmount` → **`_G.unload_mya`**.

## `games/Neighbors_110400717151509/`

- **PlaceIds:** `110400717151509`, `12699642568` (same module in config).
- **Entry:** `init.lua` fetches bundle **`runtime.lua`** then **`gui.lua`**.
- **Runtime fragments:** Under **`runtime/`** — e.g. **`piano_engine.lua`**, **`visuals.lua`**, **`movement.lua`**, **`targeting.lua`**, **`exports.lua`** (no numeric prefixes).
- **Teardown:** **`_G.unload_mya`**.

## `games/_template.lua`

- **Purpose:** Copy starter for new modules (not loaded unless you register it in config).
- Shows **`ctx.notify`**, **`ctx.uiFactory(theme)`**, and a pattern for storing **`_connections`** to disconnect in **`unmount`**.

## Config snapshot

Update **`06_module_catalogue.md`** when you add or remove supported games so readers stay aligned with **`config.lua`**.
