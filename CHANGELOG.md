# Changelog

## 1.0.20

More Forever haste wordings and maximum Energy shorten.

### Added

- `Improves your haste by` and `Increases your haste by` become `+% Haste`.
- `Increases your maximum Energy by N` becomes `+N Maximum Energy`.

## 1.0.19

Haste, creature bonuses, and enchant lines shorten. The replace-item summary uses the same regen names.

### Added

- `Increases attack and casting speed by 1%.` becomes `+1% Haste`. A fractional percent keeps one decimal, and `1.00` is shown as `1`.
- A bonus against one creature type becomes `+12 Spell Damage vs Undead` or `+9 Attack Power vs Humanoids`.
- `Enchanted: Stamina +1 and Armor +8` becomes `+1 Stamina and +8 Armor`. A named enchant stays as written.
- In the replace-item summary, mana regen is `mp5` and health regen is `Health per 5 sec`.

### Changed

- Ranged attack power, health every 5 seconds, `Increases defense by`, spell resistance pierce, and the shorter healing sentences shorten the same way as the other stats.

## 1.0.18

The stat snapshot no longer errors while auras are hidden.

### Fixed

- Aura scans are skipped while auras are secret, so the snapshot refresh does not throw.

## 1.0.17

Healing Power stays above Spell Damage.

### Changed

- When an item has both, Healing Power is the upper line. Spell Damage stays under it.

## 1.0.16

Attack power shows the Strength or Agility that matches it.

### Added

- An attack power line shows the Strength that gives the same melee attack power. Rogue and Hunter also see the Agility.

## 1.0.15

The minimap button tooltip is shorter.

### Changed

- The minimap button tooltip says the button opens settings.

## 1.0.14

Same stat lines. Chat output matches the other Joipov addons.

### Changed

- Status text goes through the shared print helper. Debug lines stay silent unless debug is turned on.

## 1.0.13

The mana note beside Spirit is blue.

### Changed

- A Spirit line shows `(30 / 9.9 mp5)` in blue.

## 1.0.12

Stat lines use the normal green again.

### Changed

- Shortened stats are green, the same as the game's other bonus lines.

## 1.0.11

Each stat has its own color. Healing is called Healing Power.

### Changed

- Mana per 5 seconds is blue, Healing Power is green, and spell damage is purple. Strength is red, Agility is gold, and the other stats follow the same idea.
- A healing line shows `+48 Healing Power`.

## 1.0.10

Attack power is named in full.

### Changed

- A Strength or Agility note says `5 Attack Power`. An item line that says `+5 Power` becomes `+5 Attack Power`.

## 1.0.9

Healing and spell damage are two rows, and mana per 5 seconds is a short line. Spirit shows both regen rates as one note.

### Changed

- A line that names both shows Healing, then Spell Damage under it.
- `Equip: Restores 5 mana per 5 sec.` becomes `+5 mp5`.
- A Spirit line shows `(30 / 9.9 mp5)`. The first number is at rest. The second is while casting.

## 1.0.3

Spirit shows the mana per 5 seconds it is worth for your character.

### Added

- A Spirit line shows mana per 5 seconds at rest and while casting, from your own regen.

## 1.0.2

Healing and spell damage stay separate. A line that names both keeps both numbers.

### Changed

- A combined magic line shows Spell Damage and Healing. It no longer says Spell Power.
- A line that gives one healing amount and a different spell damage amount keeps both.

## 1.0.1

The minimap setting greys out while the addon is off, the same as the other Joipov addons.

### Changed

- **Minimap button** greys out while **Enable Gear Stats** is off.

## 1.0.0

Shortens long item stat lines and shows what Strength, Agility, and mana per 5 seconds are worth for your class.

### Added

- **Shorten stat lines** turns a long stat sentence into a short green line. `Use:` and `Chance on hit:` stay as written.
- **Show stat values** adds attack power and armor for Strength and Agility, and the Spirit behind mana per 5 seconds, at rest and while casting.
- `/gs` and `/gearstats` open settings. The minimap button and the addon compartment do too.
