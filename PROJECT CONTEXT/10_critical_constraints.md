# Critical constraints

## Legal and platform rules

- The root **`README.md`** states that automating gameplay in experiences you do not own may violate **[Roblox Terms of Use](https://en.help.roblox.com/hc/en-us/articles/203625345)**. Treat this project as **high-risk** from a policy perspective; maintainers and users are responsible for compliance.

## URLs and hosting

- **`BASE_URL` / `MYA_BASE_URL` must resolve** to the folder that contains **`config.lua`**, **`hub.lua`**, **`lib/`**, **`games/`**, etc. A wrong branch name, private repo without token, or missing trailing slash handling causes cryptic failures.
- **Relative paths in `config.lua` are not filesystem paths** at runtime—they are HTTP suffixes.

## Secrets

- **Never commit** live Junkie keys. Use **`mya_junkie_key.txt`** locally (gitignored) or environment-appropriate secret storage.
- **`mya_junkie_key.example.txt`** is a placeholder only.

## Executor variance

- **`loadstring`** must exist or nothing loads.
- **Dumper** assumes a rich executor API surface; hub and simple games do not.
- **Junkie flow** assumes **`getgenv`** for globals; raw loader only needs what **`loader.lua`** uses.

## Hub lifecycle

- Successful mount of a **supported** game **destroys the hub**. Features that “live in the hub” must be redesigned if you need the hub to remain visible (would require code changes—out of scope for this doc).

## User-facing copy in UIs

- **No parenthetical asides** in hub text, in-game module labels, toasts, or hint rows—do not wrap clarifications in `()` or similar.
- **No stray explanatory blocks** under toggles or in panels unless the user explicitly asks for that copy; prefer short control labels over implementation trivia or filler paragraphs.

## Undocumented files

- **`piano.txt`** is intentionally excluded from this context set until explicitly analyzed later.
