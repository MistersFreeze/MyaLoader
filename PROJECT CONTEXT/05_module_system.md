# Module system (per-game)

## Routing

**Default:** Support is determined by **`game.PlaceId`** against **`config.SUPPORTED_GAMES`**, a map:

```lua
[PLACE_ID] = "path/relative/to/host/root.lua"
```

Paths are **suffixes** appended to `BASE_URL` (the hosted repo root). Example: `games/Operation-One_72920620366355/init.lua`.

**Universal:** **`games/MyaUniversal/init.lua`** is not registered by PlaceId. The hub **Universal** tab loads it on demand (same `mount` / `unmount` contract; context may omit `panel` / `getPlaceId` where unused).

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

Multi-file games derive a **directory URL** from `baseUrl` + dirname(`gameScriptPath`) and HttpGet additional files themselves (see Operation One / Neighbors).

**Repo-root `lib/` from games:** Some **`init.lua`** files also set **`_G.MYA_REPO_BASE`** to the **hosted repo root** (`normalizeBase(ctx.baseUrl)`) and **`_G.MYA_FETCH`** to the same **`fetch`** used for game files. **`gui.lua`** then loads **`lib/mya_game_ui.lua`** from that root (see **`03_wrappers.md`**). This is required for the shared in-game hub shell, not for hub-only modules.

**Runtime bundles:** Some **`runtime.lua`** files **return** `function(env)` where **`env.fetch`** and **`env.base`** load ordered fragments under **`runtime/`**, then **`loadstring` once** on the concatenation so **one** shared lexical scope is preserved (equivalent to a monolith).

## Lifecycle

1. **`loader.lua`** (and **`loader_local.lua`**) wait for **`game.Loaded`** and briefly for **`game.PlaceId ~= 0`** before HttpGetting **`config.lua`** / **`hub.lua`**. The hub defers its first **`tryMountGame()`** the same way so **`PlaceId`** and **`SUPPORTED_GAMES`** match the live experience.
2. Hub builds UI, then calls **`tryMountGame()`** (after defer).
3. If the place is unsupported, the Games tab shows a message and the hub **stays open**.
4. If supported, hub HttpGets the module, calls **`mount(ctx)`**, sets **`mountedModule`**, then **destroys the hub GUI** (`closeHubAfterGameLoad`) on success so the game UI can take over.
5. On **`PlaceId`** change (teleport), hub reconnects and remounts.
6. **`unmount`** runs when clearing the mount (e.g. close button) or before remount.

## File organization conventions

- **Single file:** `games/MyGame_<PlaceId>.lua` returning the module table.
- **Folder:** `games/MyGame_<PlaceId>/init.lua` as the entry registered in config; other files loaded relative to that folder’s URL (see `06_module_catalogue.md`).
