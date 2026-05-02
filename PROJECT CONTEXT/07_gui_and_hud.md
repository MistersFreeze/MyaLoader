# GUI and HUD (hub)

## Root GUI

- **Name:** `MyaHub` — `ScreenGui` under **LocalPlayer.PlayerGui**.
- **Window:** Centered `Frame` (“Window”), draggable via **title bar** input (mouse and touch).
- **Chrome:** Minimize (collapses body), close (destroys hub and unmounts game module).

## Tabs

Default tabs (see `hub.lua`):

| Tab id | Label | Role |
|--------|-------|------|
| `home` | Home | Welcome copy and current **PlaceId** display. |
| `games` | Games | Support status and **game module panel** (`ctx.panel` target). |
| `credits` | Credits | Contributor text section in hub. |
| `myauniversal` | Mya Universal | Button to load **`games/MyaUniversal/init.lua`** (ESP, aim tools, fly, noclip, speed/jump tweaks). |
| `dumper` | Dumper | Button to HttpGet and run **`universal/dumper.lua`**. |
| `antivcban` | Anti VC Ban | Launcher for external anti-VC-ban helper script. |

Sidebar includes a **“UNIVERSAL”** category label above these tabs.

**Credits** tab lists text contributors only (no avatar / headshot fetch).

## Theme

Visuals come from **`config.THEME`** (colors, corner radius, padding). `lib/ui.lua` reads these keys when building controls.

## Status bar

Bottom **“Status”** strip shows short messages; **`notify`** from the hub and from **`ctx.notify`** in game modules updates this label until the hub closes.

## Behavior when a game loads

Supported experiences show **Load game module** on the **Games** tab (always available when supported). With **`config.AUTOLOAD_GAME_MODULE`** **`true`**, the hub also **auto-loads** the registered module after PlaceId sync (and again after teleports). The repo default in **`config.lua`** is **`false`** (manual load unless you override with **`getgenv().MYA_AUTOLOAD_GAME_MODULE`**). After a successful **`mount`**, the hub **closes automatically** (ScreenGui destroyed, drag connections disconnected) so the game module’s UI is not obscured. If **unsupported** or **load fails**, the hub remains for debugging.

**Bootstrap order:** **`loader.lua`** / **`loader_local.lua`** wait for **`game.Loaded`** (and up to ~15 seconds for a non-zero **`PlaceId`**) before HttpGetting **`config.lua`** and **`hub.lua`**. The hub finishes building its UI, then **`task.defer`** syncs **`game.PlaceId`** and the Games tab banner after the same readiness checks so **`SUPPORTED_GAMES`** matches the joined experience, then runs **`maybeAutoloadFromConfig()`** when autoload flags allow.

The **Games** tab lists **`config.SUPPORTED_GAMES`** PlaceIds; human-readable names come from **`hub.lua` → `GAME_DISPLAY_NAMES`** (update when you add a game).

## Error GUI (`loader.lua`)

If bootstrap fails before the hub runs, **`loader.lua`** shows **`MyaLoaderError`** with a red error string (separate from the hub).
