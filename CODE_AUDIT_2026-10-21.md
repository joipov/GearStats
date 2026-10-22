# Gear Stats audit

Target: World of Warcraft Forever, `## Interface: 16001` (client 1.60.1.70425), Lua 5.1.
Compared 2026-10-21 against EasyGreenStats 1.3.0 (2026-10-17), PrettyTooltip
1.3.5 (2026-10-21), and ForeverBiS beta-0.0.81 (2026-10-21). Behaviour only:
EasyGreenStats and ForeverBiS ship no licence, so nothing was taken from them.

This note is for development. It is not shipped in the addon zip.

## What changed in 1.0.21

- `ns.OnItemTooltip` screens `IsForbidden()` and `IsProtected()` and only
  calls `Show()` on a tooltip that is already shown. It previously wrote to
  and could surface hidden, scanner, and embedded tooltips handed over by
  the item post-call.
- One unreadable tooltip line no longer aborts the whole conversion. A line
  whose text (or right text) is a combat secret is kept exactly as the
  client wrote it (`PushKeep`, row count preserved, `WriteRows` skips it)
  and the remaining lines still convert.
- Locale behaviour is now documented: long stat sentences match English
  text and stay as written on other locales; short primary-stat lines use
  the client's own stat names. See README "Features".
- `C_Secrets` was added to `.luacheckrc` and `.luarc.json`; luacheck is
  clean again.
- The Minimap button row stays active while the addon is off.

## Still holds

- The stat-worth snapshot (Strength/Agility/attack power, Spirit and mp5
  from the player's own regen) is event-refreshed and coalesced, never read
  from the tooltip path; last readable values are kept in combat. The
  compared addon has no equivalent and none was needed.
- Rows are reused tables; no allocation per hover. Secret checks stay
  canaccess-aware. Its text-idempotent rewrite needs no dedup flag.
- Registration stays `TooltipDataProcessor.AddTooltipPostCall` at file
  scope; `TooltipDataProcessor` is a client-always API on this build per
  the house reference order, so there is no existence guard.

## Checked in the client (manual pass, 1.0.21)

- [ ] In combat: hover an item with several stat lines — lines still
      shorten; any hidden line keeps its original wording.
- [ ] Hover items in bags, character, inspect, and chat links; no tooltip
      appears that was not already on screen.
- [ ] With PrettyTooltip at defaults: the combined healing/damage sentence
      must not show twice (once in its wording, once as an extra row).

## Recorded decisions

- No per-stat toggles and no buff/aura conversion were added; that is the
  compared addon's feature breadth, not a correctness gap.
- No silent `pcall` around the rewrite. Errors reach BugSack, per house
  style, instead of the compared addon's once-per-session print.
