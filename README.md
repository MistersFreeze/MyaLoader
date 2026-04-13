# Mya

Executor-oriented Roblox script base: a small **loader**, a **hub** GUI, and **per-game modules** selected by `game.PlaceId`.

## Layout

| File | Purpose |
|------|---------|
| `loader.lua` | Only file you paste first; set `BASE_URL`, then fetches `config.lua` and `hub.lua`. |
| `config.lua` | Branding, theme, `SUPPORTED_GAMES` map (PlaceId → path under your host root). |
| `hub.lua` | Builds the window, loads `lib/*`, mounts the game module for the current place. |
| `lib/util.lua` | `HttpGet`, safe `loadstring`, `loadModuleFromUrl`. |
| `lib/ui.lua` | Themed frames, buttons, scroll areas. |
| `games/<GameName>_<PlaceId>/` | Per-game folder: at minimum `init.lua` (`mount` / `unmount`). Multi-file games add `runtime.lua`, `gui.lua`, etc. and load them via `ctx.baseUrl` (see Operation One). |
| `games/example.lua` | Tiny sample module (single file). |
| `loader_jnkie.lua` | Optional entry for [Junkie / jnkie.com](https://jnkie.com/) (see below). |

## Hosting

### GitHub raw (or any static URL tree)


1. Push this folder to a GitHub repository (or any host that serves raw `.lua` text).
2. Copy the **raw** base URL for the branch root, e.g. `https://raw.githubusercontent.com/MistersFreeze/MyaLoader/main/`.
3. Edit `loader.lua` and set `BASE_URL` to that URL (trailing slash required).
4. In your executor, run the full `loader.lua` script (paste or `loadstring(game:HttpGet(YOUR_LOADER_RAW_URL))()`).

### Junkie (jnkie.com)

Junkie’s dashboard gives **one download URL per Lua script**, not a whole folder like `raw.githubusercontent.com/.../main/`. Mya is split across many files (`config.lua`, `hub.lua`, `lib/*`, …), so you typically:

1. **Keep hosting those files** on a host with stable paths (public GitHub raw, VPS, etc.) and set `MYA_BASE_URL` inside [`loader_jnkie.lua`](loader_jnkie.lua) to that root (same idea as `BASE_URL` in `loader.lua`).
2. **Upload** the contents of `loader_jnkie.lua` to Junkie (Lua Scripts → Original Code). Users run the **Junkie CDN URL** Junkie gives you; that script sets `getgenv().MYA_BASE_URL`, then `HttpGet`s `loader.lua` from your static host and runs it.

- Junkie expects `getgenv().SCRIPT_KEY` early; `loader_jnkie.lua` sets `JUNKIE_PLACEHOLDER_KEY = "KEYLESS"` for keyless dashboard scripts.
- **`SHOW_KEY_UI`** (default on) shows an in-game **TextBox**; keys are checked with **`USE_JUNKIE_VALIDATION`** + Junkie `check_key`, or with **`CUSTOM_SECRET`** if you turn Junkie validation off. Invalid keys show text on the panel — **no kick**.
- Set **`SHOW_KEY_UI = false`** to load Mya immediately (no prompt).
- Set `USE_JUNKIE_KEYS = true` and fill `JUNKIE_SERVICE` / `JUNKIE_IDENTIFIER` to use the [Junkie SDK](https://jnkie.com/sdk/library.lua) (`loader_jnkie.lua` includes a minimal stub — replace the key loop with your own UI per [their docs](https://docs.jnkie.com/roblox-sdk/external-loader)).

To put **everything** in a single Junkie upload with **no** extra `HttpGet` chain, you would need one bundled `.lua` build (not generated in this repo).

## Add a supported game

1. Copy `games/_template.lua` to `games/<name>.lua` and implement `mount` / `unmount`.
2. In `config.lua`, add an entry: `[PLACE_ID] = "games/<name>.lua"`.
3. Find **PlaceId**: Roblox Creator Dashboard for your experience, or read `game.PlaceId` in-game while testing.

To try the bundled example, add:

```lua
SUPPORTED_GAMES = {
  [YOUR_PLACE_ID] = "games/example.lua",
},
```

Use your real `YOUR_PLACE_ID` from the experience where you run the script.

## Game module API

Returned table must include:

- `mount(ctx)` — `ctx.panel` is a `Frame` for your UI; `ctx.notify(msg)` updates the hub status bar; `ctx.getPlaceId()` returns the current place; `ctx.theme` and `ctx.uiFactory` match the hub theme helpers.
- `unmount()` — disconnect loops and destroy instances you created.

## Errors

If loading fails, `loader.lua` shows a red error panel with the message. Typical issues: wrong `BASE_URL`, file not on `main`, or HTTP blocked by the executor.

## Notice

Automating gameplay in experiences you do not own may violate the [Roblox Terms of Use](https://en.help.roblox.com/hc/en-us/articles/203625345). Use this template responsibly.
