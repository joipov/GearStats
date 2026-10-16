# Gear Stats

Shortens long stat sentences on item tooltips, and adds what Strength, Agility, attack power, and mana per 5 seconds are worth for your class.

Target client: World of Warcraft **Forever** (`## Interface: 16001`).

## Features

- A long line such as `Equip: Restores 5 mana per 5 sec.` becomes `+5 mp5`. Healing is called Healing Power. `Use:` and `Chance on hit:` stay as written. A set bonus keeps its `Set:` prefix.
- `Increases attack and casting speed by 1%.` becomes `+1% Haste`. A bonus against one creature type becomes `+12 Spell Damage vs Undead` or `+9 Attack Power vs Humanoids`.
- `Enchanted: Stamina +1 and Armor +8` becomes `+1 Stamina and +8 Armor`. A named enchant stays as written.
- In the "if you replace this item" summary, mana regen is `mp5` and health regen is `Health per 5 sec`. The summary keeps the game's color, and it does not get the Strength or Spirit notes.
- Strength shows the attack power it gives your class. Agility shows attack power when the class gets it, ranged attack power for Warrior, Rogue, and Hunter, and armor (2 per point).
- Attack power shows the Strength that matches it. Rogue and Hunter also see the Agility. That Agility figure is the melee attack power only. Armor, crit, and ranged attack power stay on the Agility line.
- Mana per 5 seconds shows the Spirit that matches it at rest and while casting. The split is the five-second rule: spending mana is what suppresses Spirit, not being in combat. The rate comes from your character, so class, intellect, buffs, and talents are already in it. A priest with Meditation at 33% sees about three times as much Spirit while casting as at rest.
- Spirit shows `(30 / 9.9 mp5)` in blue. The first number is at rest. The second is while casting.
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
| `Convert.lua` | Attack power, Strength, Agility, armor, and the Spirit and mp5 exchange |
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

Releases: push an annotated tag (`git tag -a 1.0.9 -m "1.0.9"`). The
`Package and release` workflow runs BigWigsMods/packager, which reads the game
version from the TOC and the manual changelog from `CHANGELOG.md`.
The audit note is not shipped.

## Verifying in-game

- Hover a green `Equip:` stat and a `+Strength` line. The long line shortens and stays green. A healing-and-damage sentence is two rows, Healing Power first. `+5 mp5` names the Spirit at rest and while casting. `+28 Attack Power` names the Strength that matches it, and the Agility for a rogue or hunter. Haste, a creature bonus, and `Enchanted: Stamina +1 and Armor +8` shorten too. The replace-item summary says `mp5`.
- A Spirit line shows `(30 / 9.9 mp5)`. The first number is at rest. The second is while casting, and it is `0` with no retention talent.
- `Use:` and `Chance on hit:` are unchanged.
- `/gs` and the compartment open settings. Turning the addon off puts the original lines back.
- In combat the Spirit note keeps its last reading and gains a `~`.
- Watch `BugSack` (or the default error frame) through a combat session.
