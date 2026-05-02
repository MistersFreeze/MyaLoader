# Module catalogue

Games live under **`games/`**. **Place-specific** modules are listed in **`config.lua` → `SUPPORTED_GAMES`**.

## `games/example.lua`

- **Purpose:** Minimal demo proving the pipeline works for a PlaceId you add in config.
- **Structure:** Single file; exports `mount` / `unmount` (no-op unmount).

## `games/MyaUniversal/`

- **PlaceId:** None (not in `SUPPORTED_GAMES`).
- **Launch:** Hub sidebar **Universal → Mya Universal** (loads `init.lua` via `Util.loadModuleFromUrl`).
- **Features:** ESP highlights, aim assist, silent aim (workspace-first `__namecall` Raycast hook with re-entrancy guard), triggerbot, fly, noclip, walk/jump; crosshair-ring arrows ESP (optional stud distance); **Delete** toggles menu.
- **Files:** `init.lua` sets **`MYA_REPO_BASE`** + **`MYA_FETCH`**, then **`runtime.lua`** (bundle under **`runtime/`**) → **`gui.lua`**. **`runtime.lua`** HttpGets **`lib/mya_combat_helpers.lua`** from the repo root and injects it as **`Combat`** for shared team/LOS/hit-part logic. **`gui.lua`** loads **`lib/mya_game_ui.lua`** (`createHubShell`, tabs + sub-tabs, configs/settings).
- **Teardown:** **`_G.unload_mya_universal`**.

## `games/Operation-One_72920620366355/`

- **PlaceId:** `72920620366355` (Operation One).
- **Entry:** `init.lua` (registered in `config.lua`).
- **Pattern:** `init.lua` computes **`base`**, sets **`MYA_REPO_BASE`** + **`MYA_FETCH`**, fetches **`runtime.lua`** (returns a **bundle loader** `function(env)` with `env.fetch` / `env.base`), then **`gui.lua`**. Calls **`_G.MYA_OP1_RUN_UI_SYNC`** if defined.
- **GUI:** **`lib/mya_game_ui.lua`** (`defaultTheme`, **`createHubShell`**) for the window shell (tabs **Combat**, **Visuals**, **Misc**, **Configs**; Combat and Visuals have sub-pages). **Visuals → Player ESP** includes **crosshair arrows** (Drawing, pink, off-screen targets only — same visibility rule as Mya Universal / AR2) plus ring-radius slider and optional stud distance labels. **Misc → Menu bind** defaults to **Delete** (keyboard or mouse); **Misc → Unload** is a themed **TextButton** (not a toggle). Runtime **`menu_unload_bootstrap.lua`** toggles **`_G.user_interface`**. JSON configs under **`mya_op1_configs`** in **`gui.lua`**.
- **Runtime:** Ordered fragments under **`runtime/`** concatenated into one chunk; backup **`runtime_monolith.lua`** should stay aligned when changing bootstrap/menu behavior.
- **Teardown:** `unmount` → **`_G.unload_mya`**.

## `games/Neighbors_110400717151509/`

- **PlaceIds:** `110400717151509`, `12699642568` (same module in config).
- **Entry:** `init.lua` sets **`MYA_REPO_BASE`** + **`MYA_FETCH`**, fetches bundle **`runtime.lua`** then **`gui.lua`**.
- **GUI:** **`lib/mya_game_ui.lua`** (default window size matches Universal: **540×400**). Tabs: Piano, Visuals, Piano Settings, Misc, **Settings** (unload + hints). Notifications parent to **PlayerGui** (toast `createNotifyStack` option). Rows use theme **`C.panel`** + rounded corners.
- **Piano:** MIDI load/play, speed/position sliders; **queue (next song):** separate path/URL into **`load_midi_into_queue`**, **queue start (0–1)**, **Play queued song** + optional **keybind** (default **F9**) — runtime in **`runtime/piano_engine.lua`** (`play_queued_song`, etc.). Backup single file: **`runtime_monolith.lua`** (keep in sync when changing engine exports).
- **Runtime fragments:** Under **`runtime/`** — **`piano_engine.lua`**, **`visuals.lua`**, **`movement.lua`**, **`targeting.lua`**, **`exports.lua`** (order defined in **`runtime.lua`**).
- **Teardown:** **`_G.unload_mya`**.

## `games/FlexYourFPS_18667984660/`

- **PlaceId:** `18667984660` (Flex Your FPS And Ping).
- **Entry:** `init.lua` (registered in `config.lua`).
- **Pattern:** **`MYA_REPO_BASE`** + **`MYA_FETCH`**, **`runtime.lua`** bundles **`runtime/state.lua`** + **`runtime/flex.lua`**, then **`gui.lua`** (`lib/mya_game_ui.lua`).
- **Features:** Sliders — **FPS × 1–15**, **Ping × 0.1–10**, **Resolution × 0.1–10** (billboard `WxH` text when a matching label exists + **`settings().Rendering.QualityLevel`**); local FPS from **PreRender** counter; ping from **`Player:GetNetworkPing()`** (seconds → ms). Toggle to pause flex; **Insert** menu; **Unload** → **`_G.unload_mya`**.
- **Teardown:** **`_G.unload_mya`**.

## `games/ViolenceDistrict_93978595733734/`

- **PlaceId:** `93978595733734` — Violence District, DbD-style asym horror.
- **Entry:** `init.lua`, registered in `config.lua`. Loads **`gui.lua`** with **`MYA_REPO_BASE`** and **`MYA_FETCH`** like Flex Your FPS.
- **GUI:** **`lib/mya_game_ui.lua`** hub shell. **Visuals:** pink other **Survivors**; **Hooked** and **Knocked** models from **`CollectionService`** using the same rules as dumped **`Highlight-forsurvivor`**; red **killer** from **`Teams.Killer`**; **Generator** models with **`RepairProgress`**-lerped highlight fill plus a **`BillboardGui`** percent label; exits, levers, vaults, pallets; **opened** map doors only after every in-map generator **`RepairProgress`** is **100** or more; trapdoor name scan after **`Remotes.Generator.Escapetime`** when one survivor remains. **Killer** team: optional HUD listing recent **`Remotes.Killers.Killer`** **`CooldownEvent`**, **`ActivatePower`**, **`PowerDoneDeactivating`**, **`Deactivate`**, and **`IdleRefreshEvent`** **`OnClientEvent`** lines. **Assist:** auto skill check via **`VirtualInputManager`**. **Insert** toggles menu; **Unload** → **`_G.unload_mya_vd`**.

## `games/PrisonLife_155615604/`

- **PlaceId:** `155615604` (Prison Life).
- **Entry:** `init.lua` (registered in `config.lua`). Config merge: **`getgenv().MYA_PRISON_LIFE_CONFIG`** (or **`MYA_UNIVERSAL_CONFIG`**) over **`config.lua`** defaults.
- **Pattern:** Same bundle style as Mya Universal — **`runtime.lua`** prepends **`lib/mya_combat_helpers.lua`** as **`Combat`**, concatenates **`runtime/*.lua`**, then **`gui.lua`** (`lib/mya_game_ui.lua`).
- **Game-specific:** Prison Life exposes **`Teams.Inmates`**, **`Teams.Guards`**, **`Teams.Criminals`**. Separate **Prisoner check** toggles (Inmates team) under **Aim assist**, **Silent aim**, and **Visuals → ESP**, independent of team check. Triggerbot follows aim assist targeting. **Movement → Car flight**: bind + speed slider; applies **`BodyVelocity`** to the vehicle model while seated in a **`VehicleSeat`**. Legacy config key **`pl_skip_inmates = true`** still maps all three prisoner checks on when the per-mode keys are omitted.
- **Teardown:** **`_G.unload_mya_universal`**.

## `games/ApocalypseRising2_863266079/`

- **PlaceIds:** `863266079`, `93911318070665` (same `init.lua` in `config.lua`).
- **Entry:** `init.lua` merges **`games/ApocalypseRising2_863266079/config.lua`** with **`getgenv().MYA_AR2_CONFIG`** into **`MYA_UNIVERSAL_CONFIG`**, runs a **Mya Universal** runtime bundle plus **`runtime/movement_ar2_stub.lua`** (no flight/noclip/walk module) and **`runtime/tracers.lua`**, then **`gui.lua`**.
- **Features:** Shared universal ESP / aim / silent aim / triggerbot / weapon mods; AR2-only **tracers**; menu **Delete** (same shell pattern as Universal).
- **Teardown:** **`_G.unload_mya_universal`**.

## `games/ProjectDelta_7353845952/`

- **PlaceIds:** `7353845952`, `7336302630` → same module.
- **Entry:** `init.lua`; **`MYA_UNIVERSAL_CONFIG`** merge pattern similar to other universal-style games; **`gui.lua`** uses **`lib/mya_game_ui.lua`**.

## `games/MicUp_15546218972/`

- **PlaceIds:** `15546218972`, `112399855119586` → same module (Corner / MicUp).
- **Entry:** `init.lua` + runtime bundle + **`lib/mya_game_ui.lua`** GUI.

## `games/DesolateValley_11574110446/`

- **PlaceId:** `11574110446`.
- **Entry:** `init.lua` + **`lib/mya_game_ui.lua`** GUI.

## `games/SecoursDeFranceRP_8392374718/`

- **PlaceId:** `8392374718`.
- **Entry:** `init.lua`; GUI under **`lib/mya_game_ui.lua`** (alternate parent pattern in module).

## `games/BiteByNight_70845479499574/`

- **PlaceId:** `70845479499574`.
- **Entry:** `init.lua` + runtime + **`lib/mya_game_ui.lua`** GUI.

## `games/BoogaBooga_11729688377/`

- **PlaceId:** `11729688377` (Booga Booga).
- **Entry:** `init.lua` (registered in `config.lua`).
- **Pattern:** `init.lua` sets **`MYA_REPO_BASE`** + **`MYA_FETCH`**, runs **`runtime.lua`** bundle (`runtime/state.lua`, `runtime/esp.lua`, `runtime/exports.lua`), then loads **`gui.lua`**.
- **GUI:** **`lib/mya_game_ui.lua`** shell with tabs **Visuals / Movement / Misc / Configs / Settings**.
- **Visuals:** **Player ESP** (highlight, tracers, health bar, distance, usernames, team color mode), plus **Wandering Trader ESP** and optional trader tracers.
- **Movement:** **Noclip** (toggle + bind), **Speed** (toggle + bind + slider), **Fly** (toggle + bind + speed slider).
- **Misc:** **NoClipCam** and **Water Walker**.
- **Config system:** In-GUI create/load/save/delete config files via JSON in `mya_booga_configs`.
- **Removed features:** **Item ESP**, **AutoPickup**, and **Pickup Helper** are no longer present in this module.
- **Teardown:** **`_G.unload_mya_booga`**.

## `games/_template.lua`

- **Purpose:** Copy starter for new modules (not loaded unless you register it in config).
- Shows **`ctx.notify`**, **`ctx.uiFactory(theme)`**, and a pattern for storing **`_connections`** to disconnect in **`unmount`**.

## Config snapshot

Update **`06_module_catalogue.md`** when you add or remove supported games so readers stay aligned with **`config.lua`**.

When you add a PlaceId, also add **`hub.lua` → `GAME_DISPLAY_NAMES`** (Games tab labels) and ensure **`loader.lua`** / **`hub.lua`** bootstrap notes in **`PROJECT CONTEXT`** stay accurate (see **`09_workflows.md`**).
