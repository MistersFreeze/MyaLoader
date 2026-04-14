# Junkie distribution (`loader_jnkie.lua`)

## Why this file exists

[Junkie](https://jnkie.com/) hosts **one script per product**. Mya is **multi-file** (`config.lua`, `hub.lua`, `lib/*`, `games/*`), so the Junkie upload is a **thin client**: it sets **`getgenv().MYA_BASE_URL`**, optionally handles **keys**, then HttpGets your hosted **`loader.lua`** and runs it.

## Key globals

| Global | Role |
|--------|------|
| **`getgenv().MYA_BASE_URL`** | Static host root; **`loader.lua`** prefers this over its baked-in `BASE_URL`. |
| **`getgenv().SCRIPT_KEY`** | Set **before** Junkie’s CDN runs validation when using keyed products; `loader_jnkie.lua` sets it from **`JUNKIE_LICENSE_KEY`** or **`KEYLESS`**. |

## Configuration knobs (file top)

- **`JUNKIE_LICENSE_KEY`** — Paste UUID here or leave empty and use file / UI.
- **`TRY_LOAD_KEY_FROM_FILE` / `JUNKIE_KEY_FILE`** — Read key from executor **`readfile`** (e.g. `mya_junkie_key.txt`).
- **`USE_JUNKIE_VALIDATION`** — If true, loads Junkie SDK from **`https://jnkie.com/sdk/library.lua`** and validates with **`Junkie.check_key`** using **`JUNKIE_SERVICE`**, **`JUNKIE_IDENTIFIER`**, **`JUNKIE_PROVIDER`**.
- **`SHOW_KEY_UI`** — If true, shows **`MyaKeyGate`** until the user submits a valid key (or closes); if false, runs **`runMyaLoader()`** immediately.
- **`CUSTOM_SECRET`** — Only when **`USE_JUNKIE_VALIDATION`** is false: simple shared password path.

## Validation implementation

**`tryValidateKey`** loads the remote SDK via HttpGet + loadstring, configures service/identifier/provider, then calls **`check_key`**. On success, it updates **`getgenv().SCRIPT_KEY`** and runs **`runMyaLoader`**, which HttpGets **`MYA_BASE_URL .. "loader.lua"`** and executes the chunk.

## User-facing errors

Invalid keys surface in the key gate UI; loader failures spawn **`MyaLoadError`** with the error text. See comments at top of **`loader_jnkie.lua`** for Junkie-specific troubleshooting (HWID, dashboard identifiers).

## Docs link

Official external loader notes: [Junkie Roblox SDK — external loader](https://docs.jnkie.com/roblox-sdk/external-loader).
