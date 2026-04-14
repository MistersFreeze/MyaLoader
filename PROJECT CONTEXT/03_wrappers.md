# Wrappers (shared library layer)

Mya centralizes cross-cutting behavior in **`lib/`** so `hub.lua` and game modules stay smaller.

## `lib/util.lua`

Role: **thin, safe wrappers** around HTTP fetch and dynamic compilation.

- **`Util.httpGet(url)`** — `pcall` around `game:HttpGet`; returns `(body, err)`.
- **`Util.loadstringCompile(source, chunkName)`** — Returns `(fn, err)` for debuggable chunk names (`@"path"`).
- **`Util.loadModuleFromUrl(url, chunkName)`** — HttpGets, compiles, **runs** the chunk once, returns **whatever the chunk returns** (intended to be a game module table with `mount` / `unmount`).

This module **returns** the `Util` table (not a function).

## `lib/ui.lua`

Role: **themed UI factory** — no assets, only Instances.

- Exported as **`return function(theme) ... end`**: pass `config.THEME` from the hub.
- Provides helpers such as **`corner`**, **`label`**, **`button`**, **`primaryButton`**, **`panel`**, **`scroll`** — all parameterized by `theme` (colors, padding, corner radius).

Game modules receive **`ctx.uiFactory`** (that same factory) so they can build UI consistent with the hub without importing `lib/ui.lua` themselves.

## Design intent

- **Hub** owns ScreenGui layout and tabs; **game modules** own content inside `ctx.panel`.
- **Utilities** (`Util`) are executor-safe patterns (pcall, clear errors); **UI** avoids external dependencies so the hub works in minimal environments.
