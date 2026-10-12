# Gear Stats audit — 2026-10-12

Target: World of Warcraft Forever, `## Interface: 16001`, Lua 5.1.
References: Ketho's vscode-wow-api annotations, the Forever API, and the other Joipov addons.

## Already in good shape

Settings, `TooltipDataProcessor`, `C_UnitAuras`, secret checks, and pooled tooltip rows were already in place. No `CODE_AUDIT` file existed before this one. `ns.CritPercent` stays a stub: Forever's crit coefficients do not match a simple curve.

## This pass

- `ns.Print`, `ns.Welcome`, and `ns.Debug` are the chat helpers. Debug lines print only when `db.debug` is on.
- TOC fields follow the house order, with `IconTexture` before `SavedVariables`.
- Ketho's annotation path stays in `.luarc.json`. That file is the library list LuaLS uses for this addon, so moving the path to the parent workspace would hide `C_Spell` when the addon is opened on its own.

## Left as-is

The tooltip post-call stays registered while the addon is disabled and returns immediately. Snapshot reads stay coalesced onto one timer.
