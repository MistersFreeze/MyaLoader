# Directory structure

Repository root layout (files that matter for understanding Mya):

```
Mya/
├── PROJECT CONTEXT/          # This documentation set (not loaded at runtime)
├── config.lua                # Hosted: branding, theme, SUPPORTED_GAMES
├── loader.lua                # Hosted: entry for raw URL / paste; waits for game.Loaded / PlaceId then fetches config + hub
├── loader_jnkie.lua          # Optional Junkie dashboard script; sets MYA_BASE_URL, keys
├── loader_local.lua          # Local dev: readfile + MYA_LOCAL_ROOT
├── hub.lua                   # Hosted: hub UI + game module mount + Universal tab
├── README.md                 # User-facing quickstart (duplicate of some context docs)
├── .gitignore                # Ignores local key file name
├── mya_junkie_key.example.txt# Example line for Junkie UUID (copy to gitignored file locally)
├── lib/
│   ├── util.lua              # HttpGet wrapper, loadstring helpers, loadModuleFromUrl
│   ├── ui.lua                # Themed UI factory (hub + ctx.uiFactory)
│   ├── mya_combat_helpers.lua  # Team filter, LOS raycasts, hit-part parsing (Mya Universal runtime + reusable)
│   └── mya_game_ui.lua       # In-game hub shell + theme + notify (Mya Universal, OP1, Neighbors gui.lua)
├── games/
│   ├── _template.lua         # Starter template (not active until registered)
│   ├── example.lua           # Minimal sample module
│   ├── MyaUniversal/         # Place-agnostic: ESP, aim, fly, noclip, walk/jump (hub tab)
│   │   ├── init.lua          # Passes repoBase + base + fetch; runtime loads ../lib/mya_combat_helpers.lua
│   │   ├── runtime.lua       # Bundle loader: prepends Combat, concatenates runtime/*.lua
│   │   ├── runtime/          # targeting, silent_aim, esp, movement, exports, …
│   │   └── gui.lua
│   ├── Operation-One_72920620366355/
│   │   ├── init.lua          # Entry registered in config
│   │   ├── runtime.lua       # Returns bundle loader; concatenates runtime/*.lua
│   │   ├── runtime_monolith.lua  # Backup of pre-split single file (optional)
│   │   ├── runtime/          # Fragment chunks (one lexical scope when bundled)
│   │   └── gui.lua
│   └── Neighbors_110400717151509/
│       ├── init.lua
│       ├── runtime.lua       # Bundle loader; concatenates runtime/*.lua (named fragments)
│       ├── runtime_monolith.lua
│       ├── runtime/          # e.g. piano_engine.lua, visuals.lua, movement.lua, …
│       └── gui.lua
│   └── FlexYourFPS_18667984660/
│       ├── init.lua
│       ├── runtime.lua
│       ├── runtime/          # state.lua, flex.lua
│       └── gui.lua
├── universal/
│   └── dumper.lua            # “Pro Script Dumper” (heavy; executor APIs required)
└── piano.txt                 # Optional / legacy; not required for hub
```

## What is “hosted”

Anything the loader HttpGets must live at **`BASE_URL` + relative path**. Local-only files (e.g. `mya_junkie_key.txt`) are read by the executor filesystem and are **not** part of the static tree unless you upload them (you should not upload secrets).

## Naming convention for game folders

Pattern: **`<ReadableName>_<PlaceId>`** with `init.lua` inside for multi-file games—makes the PlaceId obvious in Git and in URLs.

**MyaUniversal** is not keyed by PlaceId in `config`; it is launched from the hub **Universal → Mya Universal** button.

## Runtime bundles

For large games, **`runtime.lua`** may be a thin **loader** that `fetch`es multiple files under **`runtime/`** and runs **`loadstring(table.concat(...))()`** once so all `local` state shares one chunk (same as a single monolithic file).
