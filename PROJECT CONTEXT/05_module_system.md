# Module system (per-game)

## Routing

Support is determined **only** by **`game.PlaceId`** against **`config.SUPPORTED_GAMES`**, a map:

```lua
[PLACE_ID] = "path/relative/to/host/root.lua"
```

Paths are **suffixes** appended to `BASE_URL` (the hosted repo root). Example: `games/Operation-One_72920620366355/init.lua`.

## Contract for a game module

The loaded chunk must **return a table** with:

| Member | Required | Purpose |
|--------|----------|---------|
| **`mount(ctx)`** | Yes | Called when the module is activated for the current place. |
| **`unmount`** | Recommended | Called when switching games or closing the hub; clean up connections and instances. |

## Context (`ctx`) passed to `mount`

Populated in `hub.lua` (see implementation for the exact table):

- **`panel`** — `Frame` under the Games tab where the module should parent its UI.
- **`notify(msg)`** — Updates hub status text.
- **`getPlaceId()`** — Returns the PlaceId captured when mounting (hub also listens for PlaceId changes).
- **`theme`** — Same table as `config.THEME`.
- **`uiFactory`** — Function `(theme) -> UI` from `lib/ui.lua` for consistent styling.
- **`baseUrl`** — `BASE_URL` string (hosted root with trailing slash behavior as provided).
- **`gameScriptPath`** — Config path string for this module (e.g. `games/MyGame_123/init.lua`).

Multi-file games derive a **directory URL** from `baseUrl` + dirname(`gameScriptPath`) and HttpGet additional files themselves (see Operation One).

## Lifecycle

1. Hub builds UI, then calls **`tryMountGame()`**.
2. If the place is unsupported, the Games tab shows a message and the hub **stays open**.
3. If supported, hub HttpGets the module, calls **`mount(ctx)`**, sets **`mountedModule`**, then **destroys the hub GUI** (`closeHubAfterGameLoad`) on success so the game UI can take over.
4. On **`PlaceId`** change (teleport), hub reconnects and remounts.
5. **`unmount`** runs when clearing the mount (e.g. close button) or before remount.

## File organization conventions

- **Single file:** `games/MyGame_<PlaceId>.lua` returning the module table.
- **Folder:** `games/MyGame_<PlaceId>/init.lua` as the entry registered in config; other files loaded relative to that folder’s URL (see `06_module_catalogue.md`).
