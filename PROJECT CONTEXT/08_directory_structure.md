# Directory structure

Repository root layout (files that matter for understanding Mya):

```
Mya/
├── PROJECT CONTEXT/          # This documentation set (not loaded at runtime)
├── config.lua                # Hosted: branding, theme, SUPPORTED_GAMES
├── loader.lua                # Hosted: entry for raw URL / paste; fetches config + hub
├── loader_jnkie.lua          # Optional Junkie dashboard script; sets MYA_BASE_URL, keys
├── hub.lua                   # Hosted: hub UI + game module mount
├── README.md                 # User-facing quickstart (duplicate of some context docs)
├── .gitignore                # Ignores local key file name
├── mya_junkie_key.example.txt# Example line for Junkie UUID (copy to gitignored file locally)
├── lib/
│   ├── util.lua              # HttpGet wrapper, loadstring helpers, loadModuleFromUrl
│   └── ui.lua                # Themed UI factory
├── games/
│   ├── _template.lua         # Starter template (not active until registered)
│   ├── example.lua           # Minimal sample module
│   └── Operation-One_72920620366355/
│       ├── init.lua          # Entry registered in config
│       ├── runtime.lua       # Loaded by init (same folder on host)
│       └── gui.lua           # Loaded by init (same folder on host)
├── universal/
│   └── dumper.lua            # “Pro Script Dumper” (heavy; executor APIs required)
└── piano.txt                 # Intentionally not documented in this pass
```

## What is “hosted”

Anything the loader HttpGets must live at **`BASE_URL` + relative path**. Local-only files (e.g. `mya_junkie_key.txt`) are read by the executor filesystem and are **not** part of the static tree unless you upload them (you should not upload secrets).

## Naming convention for game folders

Pattern: **`<ReadableName>_<PlaceId>`** with `init.lua` inside for multi-file games—makes the PlaceId obvious in Git and in URLs.
