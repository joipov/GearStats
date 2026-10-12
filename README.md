# Gear Stats

Shortens long stat sentences on item tooltips, and adds what Strength, Agility, and mana per 5 seconds are worth for your class.

Target client: World of Warcraft **Forever** (`## Interface: 16001`).

## Features

- A long line such as `Equip: Restores 5 mana per 5 sec.` becomes `+5 Mana per 5 sec`. `Use:` and `Chance on hit:` stay as written. A set bonus keeps its `Set:` prefix.
- Strength shows the attack power it gives your class. Agility shows attack power when the class gets it, ranged attack power for Warrior, Rogue, and Hunter, and armor (2 per point).
- Mana per 5 seconds shows the Spirit that matches it at rest and while casting. The split is the five-second rule: spending mana is what suppresses Spirit, not being in combat. The rate comes from your character, so class, intellect, buffs, and talents are already in it. A priest with Meditation at 33% sees about three times as much Spirit while casting as at rest.
- While a second effect also keeps Spirit regen (Mage Armor on top of a meditation talent), the higher percent is used. Those two are not added together.
- In combat the client hides regen numbers. The last reading from outside combat is kept, with a `~` in front.
- Crit from Agility is not shown. Forever's per-level coefficients do not match the public tables (paladin +10 Agility: 2.15% at 1, 1.72% at 10, 1.229% at 20, 0.935% at 30, 0.506% at 60), and a guessed curve would be wrong.
- Cat Form uses its own Agility conversion. A druid sees the class baseline, which is attack power from Strength and armor from Agility.

## Commands

| Command | Effect |
| --- | --- |
| `/gs`, `/gearstats` | Open the settings panel |

## Files

Loaded in TOC order; modules communicate only through the shared `ns` table.

| File | Concern |
| --- | --- |
| `Patterns.lua` | Which tooltip lines are stats, and the short form |
| `Convert.lua` | Attack power, armor, and mana-per-5 to Spirit |
| `Database.lua` | SavedVariables defaults, migrations, validation |
| `Snapshot.lua` | Cached class, level, regen, and casting retention |
| `Tooltip.lua` | Item tooltip rewrite |
| `MinimapButton.lua` | LibDBIcon launcher or built-in button |
| `Events.lua` | Event frame, dispatch table, tooltip post-call |
| `Options.lua` | Settings panel and slash commands |

## Development

The repository lives outside the game folder; the AddOns entry is a
directory junction to it:

```
mklink /J "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\GearStats" "D:\Repos\Joipov\GearStats"
```

Static checks (no game client needed):

```
luacheck .            # .luacheckrc: Lua 5.1, explicit WoW globals
luajit tests/run.lua  # or: lua5.1 tests/run.lua
```

LuaLS uses `.luarc.json` and Ketho's WoW API annotations. The repo-local
`.annotations/` folder declares the Forever secret-value helpers those
annotations lack.

`assets/` is release media for CurseForge and Wago (screenshots, and a logo
when one exists). The game does not load it, and it is not part of the addon
zip. Do not delete it during cleanup.

Local zip, with the addon folder at the root, written to `.release/`:

```
powershell -File package.ps1
```

Releases: push an annotated tag (`git tag -a 1.0.0 -m "1.0.0"`). The
`Package and release` workflow runs BigWigsMods/packager, which reads the game
version from the TOC and the manual changelog from `CHANGELOG.md`.
The audit note is not shipped.

## Verifying in-game

- Hover a green `Equip:` stat and a `+Strength` line. The long line shortens. Strength and Agility gain a parenthetical. Mana per 5 seconds names Spirit at rest and while casting.
- A priest with Meditation: the while-casting Spirit is larger. With the talent unlearned, the line says Spirit adds nothing while casting.
- `Use:` and `Chance on hit:` are unchanged.
- `/gs` and the compartment open settings. Turning the addon off puts the original lines back.
- In combat the Spirit note keeps its last reading and gains a `~`.
- Watch `BugSack` (or the default error frame) through a combat session.
