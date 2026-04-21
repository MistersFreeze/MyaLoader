# Workflows

## Host the scripts (GitHub raw or any static server)

1. Push this repository (or a subtree) to a branch that serves raw files.
2. Copy the **root URL** for that branch (must end with **`/`** or loaders normalize—prefer explicit slash in config).
3. Set **`BASE_URL`** in **`loader.lua`** to that root.

## Run with raw `loader.lua`

Paste the full **`loader.lua`** into the executor, or:

```lua
loadstring(game:HttpGet("YOUR_RAW_LOADER_URL", true))()
```

Fix **`BASE_URL`** inside the hosted `loader.lua` first.

## Run with Junkie

1. Keep hosting **`config.lua`**, **`hub.lua`**, **`lib/`**, **`games/`**, etc. at a stable URL.
2. Set **`MYA_BASE_URL`** inside **`loader_jnkie.lua`** to that same root (see file header).
3. Match **`JUNKIE_SERVICE`**, **`JUNKIE_IDENTIFIER`**, and provider with your Junkie dashboard script.
4. Upload **`loader_jnkie.lua`** body to Junkie; users run Junkie’s CDN URL.
5. For development without committing a key, use **`mya_junkie_key.txt`** (gitignored) with **`TRY_LOAD_KEY_FROM_FILE`** — see **`11_junkie_distribution.md`**.

## Add a new supported game

1. Create **`games/MyGame_<PlaceId>.lua`** or **`games/MyGame_<PlaceId>/init.lua`** implementing **`mount`/`unmount`**.
2. Add **`[PLACE_ID] = "games/..."`** to **`config.lua` → `SUPPORTED_GAMES`**.
3. Add a **display name** for the Games tab list in **`hub.lua`** → **`GAME_DISPLAY_NAMES`** (same PlaceId key as in config). Without it, the hub falls back to showing the script path string.
4. **`loader.lua`** / **`loader_local.lua`** wait for **`game.Loaded`** (and up to ~15s for a non‑zero **`PlaceId`**) before fetching **`config.lua`** / **`hub.lua`**, so the hub’s PlaceId matches the experience. **`hub.lua`** defers **PlaceId sync** the same way, then **autoloads** the game module when **`config.AUTOLOAD_GAME_MODULE`** is **`true`** (default). Set **`AUTOLOAD_GAME_MODULE = false`** to require the **Load game module** button.
5. Update **`PROJECT CONTEXT/06_module_catalogue.md`** (and this workflow if routing changes).
6. Push to host; verify **`BASE_URL .. path`** returns 200 in a browser.
7. Join that experience in Roblox, run the loader; with autoload on, the module should mount without tapping **Load game module** (or tap it to retry). Confirm load / hub close behavior.

## Use the dumper

From hub **Dumper** tab: downloads **`universal/dumper.lua`** and runs it with the hub’s **BASE_URL** so it can fetch **`lib/mya_game_ui.lua`** (Mya window). Requires executor support for filesystem and decompilation APIs; may manipulate **CoreGui** overlay — read the script before use.

## Documentation maintenance

When you change routing or add games, update **`PROJECT CONTEXT/06_module_catalogue.md`**, **`hub.lua` → `GAME_DISPLAY_NAMES`**, and **`config.lua`** comments if they drift.
