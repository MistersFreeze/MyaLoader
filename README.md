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
| `games/*.lua` | One module per experience; exports `mount` / `unmount`. |

## Hosting

1. Push this folder to a GitHub repository (or any host that serves raw `.lua` text).
2. Copy the **raw** base URL for the branch root, e.g. `https://raw.githubusercontent.com/MistersFreeze/MyaLoader/main/`.
3. Edit `loader.lua` and set `BASE_URL` to that URL (trailing slash required).
4. In your executor, run the full `loader.lua` script (paste or `loadstring(game:HttpGet(YOUR_LOADER_RAW_URL))()`).

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
