# Roblox executor environment

Mya assumes a **client** context: `Players.LocalPlayer`, `PlayerGui`, and network fetch via Roblox’s HTTP API.

## Core Roblox services used

- **`game:GetService("Players")`** — Local player and UI parent.
- **`game:HttpGet(url, true)`** — Loads remote Lua source as strings (used everywhere for modular loading).
- **`game:GetService("UserInputService")`** — Hub window dragging.
- **`game:GetService("TweenService")`** — UI transitions in `lib/ui.lua` and hub fade-in.
- **`game:GetService("MarketplaceService")`** — Used by `universal/dumper.lua` for place name (product info).

## Executor capabilities (variable)

These are **not** guaranteed on every executor; code paths degrade or error if missing:

| Capability | Where it matters |
|------------|------------------|
| `loadstring` | Required for `loader.lua`, hub, and all remote modules. |
| `getgenv` | Used for `MYA_BASE_URL`, `SCRIPT_KEY` in Junkie flow. |
| `readfile` | Optional in `loader_jnkie.lua` to read `mya_junkie_key.txt`. |
| `writefile`, `isfolder`, `makefolder`, `decompile`, etc. | **Dumper** only; third-party script expects a feature-rich executor. |

## Load chain mental model

1. User runs a **single chunk** (paste or Junkie CDN).
2. That chunk sets globals/env (`MYA_BASE_URL`, `SCRIPT_KEY`) as needed.
3. **`loader.lua`** HttpGets `config.lua` → compile → table.
4. **`loader.lua`** HttpGets `hub.lua` → compile → call returned `function(BASE_URL, config)`.
5. **`hub.lua`** HttpGets `lib/util.lua` and `lib/ui.lua`, then HttpGets the **game module** URL from `config.SUPPORTED_GAMES[PlaceId]`.

Every hop depends on the previous URL being correct and HTTP allowed by the executor.

## Typing annotations

Several files use Luau-style type annotations (`: string`, optional types). Roblox’s `loadstring` accepts them when running under a Luau-aware environment; if an executor strips types or uses plain Lua 5.1, you may need to adjust (this repo assumes a typical modern Roblox executor).
