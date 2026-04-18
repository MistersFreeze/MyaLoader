# Project context (Mya)

This folder is the **canonical orientation** for humans and AI assistants working on the Mya repository. Read documents in numerical order for a full picture, or jump by topic.

| # | Document | What it covers |
|---|----------|----------------|
| 01 | [01_identity_and_build.md](01_identity_and_build.md) | What Mya is, tech stack, how “build” works (static hosting, no compiler) |
| 02 | [02_roblox_executor_environment.md](02_roblox_executor_environment.md) | Roblox services and executor globals the code assumes |
| 03 | [03_wrappers.md](03_wrappers.md) | Shared library layer: `lib/util.lua`, `lib/ui.lua`, `lib/mya_combat_helpers.lua`, `lib/mya_game_ui.lua` |
| 04 | [04_utilities.md](04_utilities.md) | Practical reference for `Util` helpers and UI factory usage |
| 05 | [05_module_system.md](05_module_system.md) | Per-game modules: `mount` / `unmount`, `ctx`, PlaceId routing |
| 06 | [06_module_catalogue.md](06_module_catalogue.md) | Games shipped in-repo and how they load extra files |
| 07 | [07_gui_and_hud.md](07_gui_and_hud.md) | Hub window, tabs, theme, lifecycle (including auto-close) |
| 08 | [08_directory_structure.md](08_directory_structure.md) | Repository layout and file roles |
| 09 | [09_workflows.md](09_workflows.md) | Day-to-day: host files, add a game (config + hub display names + loader notes), test, Junkie vs raw loader |
| 10 | [10_critical_constraints.md](10_critical_constraints.md) | Non-negotiables: URLs, secrets, ToS, executor variance |
| 11 | [11_junkie_distribution.md](11_junkie_distribution.md) | `loader_jnkie.lua`, keys, `MYA_BASE_URL`, SDK validation |
| 12 | [12_network_architecture.md](12_network_architecture.md) | HttpGet chain, static hosting, optional external SDK URL |

**Explicitly out of scope for v1 of this folder:** analysis of `piano.txt` (reserved for a later pass).
