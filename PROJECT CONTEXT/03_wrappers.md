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

## `lib/mya_game_ui.lua`

Role: **shared in-game window shell** for games that render their own `ScreenGui` (after the hub closes), not inside `ctx.panel`.

- Loaded at runtime with the same **`fetch`** + repo root URL as the game’s **`runtime.lua`** / **`gui.lua`** chain. Game **`init.lua`** sets **`_G.MYA_REPO_BASE`** (normalized `ctx.baseUrl` repo root) and **`_G.MYA_FETCH`** (usually the same `fetch` closure used for game files).
- **`gui.lua`** does `loadstring(fetch(repoBase .. "lib/mya_game_ui.lua"))()` and uses:
  - **`defaultTheme()`** — rose/plum palette + control colors (`C`).
  - **`createNotifyStack({ C, THEME, ts, notifParent?, gethui_support? })`** — right-side toasts.
  - **`createHubShell({ ui, THEME, C, ts, uis, titleText, tabNames, subPages, statusDefault, discordInvite?, winW?, winH?, onClose? })`** — sidebar tabs, optional sub-tab row, content host, title-bar drag, Discord / minimize / close, status line.
- **Consumers in-repo:** `games/MyaUniversal/gui.lua`, `games/Operation-One_72920620366355/gui.lua`, `games/Neighbors_110400717151509/gui.lua`.

This is **orthogonal** to **`lib/ui.lua`**: the hub uses `ui.lua`; per-game menus use `mya_game_ui.lua` when you want one consistent “Mya” window chrome across titles.

## `lib/mya_combat_helpers.lua`

Role: **stateless combat / targeting helpers** reused by **Mya Universal** and any other script that HttpGets it from the repo root.

- **`HIT_PART_NAMES`** — whitelist set for valid aim/silent hit part strings.
- **`parse_hit_part(configTable, key, defaultName)`** — reads a config key and returns a safe part name.
- **`same_team(localPlayer, otherPlayer, teamCheckEnabled)`** — when `teamCheckEnabled` is false, returns false (do not treat as “same team” skip).
- **`los_visible_exclude(origin, targetPart, lpCharacter, cameraInstance, workspaceRef)`** — LOS via `Workspace:Raycast` with **Exclude** `{ character, camera }` (classic silent-aim style).
- **`los_visible_blacklist(workspaceRef, fromPos, targetChar, targetPoint, raycastParams)`** — LOS with caller-supplied **`RaycastParams`** (e.g. blacklist after `update_vis_filter()`).

**Mya Universal wiring:** `games/MyaUniversal/init.lua` passes **`repoBase`** into **`runtime.lua`**, which HttpGets **`repoBase .. "lib/mya_combat_helpers.lua"`**, runs it once, and injects the returned table as **`Combat`** at the top of the runtime bundle (then clears **`_G.MYA_COMBAT_HELPERS`**). Fragments such as **`targeting.lua`**, **`silent_aim.lua`**, and **`state_config.lua`** call **`Combat`** instead of duplicating team/LOS/part parsing.

**Other games:** `loadstring(game:HttpGet(MYA_REPO_BASE .. "lib/mya_combat_helpers.lua"))()` and use the same API; no globals required.

## Design intent

- **Hub** owns ScreenGui layout and tabs; **game modules** own content inside `ctx.panel`.
- **Utilities** (`Util`) are executor-safe patterns (pcall, clear errors); **UI** avoids external dependencies so the hub works in minimal environments.
- **Combat helpers** (`mya_combat_helpers.lua`) keep team filters and LOS raycasts in one place; Mya Universal injects them as **`Combat`** in the runtime bundle, and other scripts can HttpGet the same file from the hosted repo root.
