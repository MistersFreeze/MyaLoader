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
3. Push to host; verify **`BASE_URL .. path`** returns 200 in a browser.
4. Join that experience in Roblox, run loader, confirm Games tab / auto-close behavior.

## Use the dumper

From hub **Dumper** tab: downloads **`universal/dumper.lua`** and executes it. Requires executor support for filesystem and decompilation APIs; may manipulate **CoreGui** overlay — read the script before use.

## Documentation maintenance

When you change routing or add games, update **`PROJECT CONTEXT/06_module_catalogue.md`** and **`config.lua`** comments if they drift.
