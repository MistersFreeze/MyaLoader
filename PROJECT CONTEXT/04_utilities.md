# Utilities (practical reference)

Quick reference for the helpers in **`lib/util.lua`** and how **`lib/ui.lua`** is consumed.

## `Util.httpGet(url): (string?, string?)`

- On success: returns the response body and `nil` error.
- On failure: returns `nil` and a stringified error.

Use this anywhere you would raw `HttpGet` when you want **consistent error handling**.

## `Util.loadstringCompile(source, chunkName): (function?, string?)`

- Wraps `loadstring` in `pcall`.
- `chunkName` becomes part of the debug name (`"@" .. name`) for stack traces.

## `Util.loadModuleFromUrl(url, chunkName): (any?, string?)`

Pipeline:

1. HttpGet body.
2. Compile with `loadstringCompile`.
3. `pcall` the compiled function with **no arguments**.
4. Return the **result** of that call (expected: a table module).

**Important:** This is **not** a Luau `require` system. The remote script must **execute** and return its export table when invoked as a function with no args—matching the pattern `return M` at file bottom.

## UI factory (`lib/ui.lua`)

After `local UI = makeUi(theme)` in the hub (or `local UI = ctx.uiFactory(theme)` in a game module):

- **`UI.label(parent, text, size?, muted?)`** — Read-only text.
- **`UI.button` / `UI.primaryButton`** — Click handlers with hover tweens.
- **`UI.panel` / `UI.scroll`** — Layout helpers for the Games tab content area.

Theme keys expected from `config.THEME` include at least: `bg`, `bgElevated`, `surface`, `border`, `text`, `textMuted`, `accent`, `danger`, `corner`, `padding` (see `config.lua`).

## Combat helpers (`lib/mya_combat_helpers.lua`)

Not part of `Util`; see **[03_wrappers.md](03_wrappers.md)**. Mya Universal’s runtime uses **`Combat.same_team`**, **`Combat.los_visible_*`**, and **`Combat.parse_hit_part`** so team checks and LOS stay consistent between aim assist, silent aim, and ESP-style rays.

## Status messaging

Hub passes **`ctx.notify(msg)`** which updates the hub status label. Game modules should use this instead of `print` for user-visible feedback.
