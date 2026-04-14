# Module catalogue

Games live under **`games/`**. Only entries in **`config.lua` → `SUPPORTED_GAMES`** are loaded.

## `games/example.lua`

- **Purpose:** Minimal demo proving the pipeline works for a PlaceId you add in config.
- **Structure:** Single file; exports `mount` / `unmount` (no-op unmount).

## `games/Operation-One_72920620366355/`

- **PlaceId:** `72920620366355` (Operation One).
- **Entry:** `init.lua` (registered in `config.lua`).
- **Pattern:** `init.lua` does **not** put all logic in one file. It:
  - Computes a **`base`** URL for the folder on your static host.
  - HttpGets **`runtime.lua`** and executes it (feature/bootstrap code).
  - HttpGets **`gui.lua`** and executes it (UI).
  - Optionally calls **`_G.MYA_OP1_RUN_UI_SYNC()`** if defined by runtime.
- **Teardown:** `unmount` calls **`_G.unload_mya`** if present (game-specific global hook).

Use this folder as the **reference for large games** that split runtime vs. GUI while still exposing one `init.lua` to the hub.

## `games/_template.lua`

- **Purpose:** Copy starter for new modules (not loaded unless you register it in config).
- Shows **`ctx.notify`**, **`ctx.uiFactory(theme)`**, and a pattern for storing **`_connections`** to disconnect in **`unmount`**.

## Config snapshot (current repo)

As of documentation generation, `config.lua` maps:

- **`72920620366355`** → **`games/Operation-One_72920620366355/init.lua`**

Update **`06_module_catalogue.md`** when you add or remove supported games so AI/human readers stay aligned with `config.lua`.
