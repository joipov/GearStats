-- Lua 5.1, explicit WoW globals. Same layout in every Joipov addon.
std = "lua51"
max_line_length = false
self = false

exclude_files = {
	".release/",
	".annotations/",
	"assets/",
}

files["tests/"] = {
	std = "lua51",
}

-- Globals this addon writes.
globals = {
	"GearStatsDB",
	"GearStats_OnAddonCompartmentClick",
	"GearStats_OnAddonCompartmentEnter",
	"GearStats_OnAddonCompartmentLeave",
	"SLASH_GEARSTATS1",
	"SLASH_GEARSTATS2",
	SlashCmdList = { fields = { "GEARSTATS" } },
}

-- WoW globals this addon reads. Anything else is an error.
read_globals = {
	"issecretvalue",
	"canaccessvalue",
	"issecrettable",
	"canaccesstable",

	"C_AddOns",
	"C_Spell",
	"C_SpellBook",
	"C_Timer",
	"C_UnitAuras",
	"Enum",
	"TooltipDataProcessor",

	"CreateFrame",
	"GetManaRegen",
	"IsPlayerSpell",
	"UnitClass",
	"UnitLevel",
	"UnitStat",

	"GameTooltip",
	"GetCursorPosition",
	"Minimap",

	"Settings",

	"print",
}
