# Identity and build

## What this repository is

**Mya** is an **executor-oriented Roblox script base** written in **Luau** (Roblox Lua). It is not a Roblox Studio plugin and not a standalone desktop app. It is meant to be pasted into a third-party Roblox **executor** or loaded via `loadstring` + `game:HttpGet` from a URL you control.

Core pieces:

- **`loader.lua`** — Minimal bootstrap: fetches `config.lua` and `hub.lua` from a **static base URL**, compiles with `loadstring`, runs the hub.
- **`config.lua`** — Returns a Lua table: branding, version, theme colors, and **`SUPPORTED_GAMES`** (maps `game.PlaceId` → path under the host root).
- **`hub.lua`** — Builds a ScreenGui hub, loads `lib/util.lua` and `lib/ui.lua` over HTTP, then loads and mounts the **per-game module** for the current place.
- **`games/`** — One module per supported experience (single file or folder with `init.lua` + friends).
- **`lib/`** — Shared HTTP helpers and themed UI constructors.
- **`universal/`** — Tools not tied to one game (e.g. script dumper), launched from the hub.
- **`loader_jnkie.lua`** — Optional entrypoint for [Junkie](https://jnkie.com/): sets `getgenv().MYA_BASE_URL`, optional key UI, then pulls and runs `loader.lua` from your static host.

There is **no build step** in this repo (no bundler, no `rojo build` artifact required). “Build” in practice means: **push Lua files to a static host** (e.g. GitHub `raw.githubusercontent.com/.../branch/`) and point `BASE_URL` / `MYA_BASE_URL` at that tree with a **trailing slash**.

## Versioning

`config.lua` exposes `VERSION` as a string for the hub title bar; it is informational only unless you add your own semantics.

## Relationship to upstream hosting

The default comments reference a public loader repo URL; your fork may use a different GitHub user/repo/branch. All paths in `config.lua` are **relative to that hosted root**, not relative to your local disk when running in-game.
