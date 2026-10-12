local _, ns = ...

-- Turns a tooltip line into a known stat, or leaves it alone. Long sentences
-- shorten; a line that is already short stays short so the note can be added.

local hit = {
	stat = nil,
	amount = 0,
	prefix = "",
	long = false,
	percent = false,
	label = "",
	text = nil,
}

local function Hit(stat, amount, prefix, isLong, percent, label, text)
	hit.stat = stat
	hit.amount = amount
	hit.prefix = prefix
	hit.long = isLong
	hit.percent = percent
	hit.label = label
	hit.text = text
	return hit
end

local function Escape(text)
	return (text:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"))
end

local function GlobalName(key, fallback)
	local value = _G[key]
	if type(value) == "string" and value ~= "" then
		return value
	end
	return fallback
end

-- Short primary lines are already "+6 Strength". The name follows the client.
local SHORT_STATS = {
	{ stat = "strength", name = GlobalName("SPELL_STAT1_NAME", "Strength"), label = "Strength" },
	{ stat = "agility", name = GlobalName("SPELL_STAT2_NAME", "Agility"), label = "Agility" },
	{ stat = "stamina", name = GlobalName("SPELL_STAT3_NAME", "Stamina"), label = "Stamina" },
	{ stat = "intellect", name = GlobalName("SPELL_STAT4_NAME", "Intellect"), label = "Intellect" },
	{ stat = "spirit", name = GlobalName("SPELL_STAT5_NAME", "Spirit"), label = "Spirit" },
}

local SHORT_PATTERNS = {}
for i = 1, #SHORT_STATS do
	local row = SHORT_STATS[i]
	SHORT_PATTERNS[i] = {
		stat = row.stat,
		label = row.label,
		pattern = "^([%+%-])%s*(%d+)%s+" .. Escape(row.name) .. "%.?$",
	}
end

local SCHOOLS = {
	Fire = true,
	Frost = true,
	Nature = true,
	Shadow = true,
	Arcane = true,
	Holy = true,
}

local WEAPONS = {
	Swords = true,
	Axes = true,
	Maces = true,
	Daggers = true,
	["Fist Weapons"] = true,
	Polearms = true,
	Staves = true,
	["Two-handed Swords"] = true,
	["Two-handed Axes"] = true,
	["Two-handed Maces"] = true,
	Bows = true,
	Guns = true,
	Crossbows = true,
	Thrown = true,
	Wands = true,
	Unarmed = true,
	Fishing = true,
}

-- One capture: the number. Checked in order, more specific lines first.
local LONG = {
	{ stat = "natureSpellCrit", label = "Nature Spell Crit", percent = true, pattern = "^Improves your chance to get a critical strike with Nature spells by (%d+)%%%.?$" },
	{ stat = "holySpellCrit", label = "Holy Spell Crit", percent = true, pattern = "^Improves your chance to get a critical strike with Holy spells by (%d+)%%%.?$" },
	{ stat = "holySpellCrit", label = "Holy Spell Crit", percent = true, pattern = "^Increases the critical effect chance of your Holy spells by (%d+)%%%.?$" },
	{ stat = "spellCrit", label = "Spell Crit", percent = true, pattern = "^Improves your chance to get a critical strike with spells by (%d+)%%%.?$" },
	{ stat = "crit", label = "Crit", percent = true, pattern = "^Improves your chance to get a critical strike by (%d+)%%%.?$" },
	{ stat = "spellHit", label = "Spell Hit", percent = true, pattern = "^Improves your chance to hit with spells by (%d+)%%%.?$" },
	{ stat = "hit", label = "Hit", percent = true, pattern = "^Improves your chance to hit by (%d+)%%%.?$" },
	{ stat = "spellPen", label = "Spell Penetration", percent = false, pattern = "^Decreases the magical resistances of your spell targets by (%d+)%.?$" },
	{ stat = "spellDamage", label = "Spell Damage", percent = false, pattern = "^Increases damage done by magical spells and effects by up to (%d+)%.?$" },
	{ stat = "healing", label = "Healing", percent = false, pattern = "^Increases healing done by spells and effects by up to (%d+)%.?$" },
	{ stat = "healing", label = "Healing", percent = false, pattern = "^%+(%d+) Healing Spells%.?$" },
	{ stat = "blockChance", label = "Block Chance", percent = true, pattern = "^Increases your chance to block attacks with a shield by (%d+)%%%.?$" },
	{ stat = "blockValue", label = "Block Value", percent = false, pattern = "^Increases the block value of your shield by (%d+)%.?$" },
	{ stat = "dodge", label = "Dodge", percent = true, pattern = "^Increases your chance to dodge an attack by (%d+)%%%.?$" },
	{ stat = "parry", label = "Parry", percent = true, pattern = "^Increases your chance to parry an attack by (%d+)%%%.?$" },
	{ stat = "defense", label = "Defense", percent = false, pattern = "^Increased Defense %+(%d+)%.?$" },
	{ stat = "attackPower", label = "Attack Power", percent = false, pattern = "^%+(%d+) Attack Power%.?$" },
	{ stat = "attackPower", label = "Attack Power", percent = false, pattern = "^Increases attack power by (%d+)%.?$" },
	{ stat = "hp5", label = "Health per 5 sec", percent = false, pattern = "^Restores (%d+) health per 5 sec%.?$" },
	{ stat = "mountSpeed", label = "Mount Speed", percent = true, pattern = "^Increases mount speed by (%d+)%%%.?$" },
	{ stat = "strength", label = "Strength", percent = false, pattern = "^Increases your Strength by (%d+)%.?$" },
	{ stat = "agility", label = "Agility", percent = false, pattern = "^Increases your Agility by (%d+)%.?$" },
	{ stat = "stamina", label = "Stamina", percent = false, pattern = "^Increases your Stamina by (%d+)%.?$" },
	{ stat = "intellect", label = "Intellect", percent = false, pattern = "^Increases your Intellect by (%d+)%.?$" },
	{ stat = "spirit", label = "Spirit", percent = false, pattern = "^Increases your Spirit by (%d+)%.?$" },
}

local function Signed(sign, digits)
	local amount = tonumber(digits)
	if not amount then
		return nil
	end
	if sign == "-" then
		return -amount
	end
	return amount
end

local function ManaText(digits, negative)
	local sign = negative and "-" or "+"
	return sign .. digits .. " mp5"
end

local function TryShort(rest, prefix)
	local digits = rest:match("^(%d+)%s+mp5$")
	if digits then
		return Hit("mp5", tonumber(digits), prefix, true, false, "mp5", ManaText(digits, false))
	end
	local sign
	sign, digits = rest:match("^([%+%-])%s*(%d+)%s+mp5$")
	local amount = sign and Signed(sign, digits)
	if amount then
		return Hit("mp5", amount, prefix, false, false, "mp5")
	end
	digits = rest:match("^(%d+)%s+[Mm]ana per 5 sec%.?$")
	if digits then
		return Hit("mp5", tonumber(digits), prefix, true, false, "mp5", ManaText(digits, false))
	end
	sign, digits = rest:match("^([%+%-])%s*(%d+)%s+[Mm]ana per 5 sec%.?$")
	amount = sign and Signed(sign, digits)
	if amount then
		return Hit("mp5", amount, prefix, true, false, "mp5", ManaText(digits, amount < 0))
	end
	for i = 1, #SHORT_PATTERNS do
		local row = SHORT_PATTERNS[i]
		sign, digits = rest:match(row.pattern)
		amount = sign and Signed(sign, digits)
		if amount then
			return Hit(row.stat, amount, prefix, false, false, row.label)
		end
	end
	return nil
end

local function TrySchool(rest, prefix)
	local school, digits = rest:match("^Increases damage done by (%a+) spells and effects by up to (%d+)%.?$")
	if school and SCHOOLS[school] then
		return Hit("schoolDamage", tonumber(digits), prefix, true, false, school .. " Spell Damage")
	end
	school, digits = rest:match("^Increases your (%a+) resistance by (%d+)%.?$")
	if school and SCHOOLS[school] then
		return Hit("resistance", tonumber(digits), prefix, true, false, school .. " Resistance")
	end
	local sign
	sign, digits = rest:match("^([%+%-])%s*(%d+)%s+All Resistances%.?$")
	local amount = sign and Signed(sign, digits)
	if amount then
		return Hit("resistance", amount, prefix, false, false, "All Resistances")
	end
	return nil
end

local function TryWeapon(rest, prefix)
	local name, digits = rest:match("^Increased (.+) %+(%d+)%.?$")
	if name and WEAPONS[name] then
		return Hit("weaponSkill", tonumber(digits), prefix, true, false, name .. " Skill")
	end
	return nil
end

local function Plus(digits, label)
	return "+" .. digits .. " " .. label
end

-- One sentence can name healing and spell damage. Healing is the first row.
local function TrySpell(rest, prefix)
	local heal, damage = rest:match("^Increases healing done by up to (%d+) and damage done by up to (%d+) for all magical spells and effects%.?$")
	if heal then
		return Hit("healing", tonumber(heal), prefix, true, false, "Healing", Plus(heal, "Healing") .. "\n" .. Plus(damage, "Spell Damage"))
	end
	local both = rest:match("^Increases damage and healing done by magical spells and effects by up to (%d+)%.?$")
	if both then
		return Hit("healing", tonumber(both), prefix, true, false, "Healing", Plus(both, "Healing") .. "\n" .. Plus(both, "Spell Damage"))
	end
	return nil
end

local function TryMana(rest, prefix)
	local digits = rest:match("^[Rr]estores (%d+) [Mm]ana per 5 sec%.?$")
		or rest:match("^[Rr]estores (%d+) [Mm]ana per 5 seconds%.?$")
	if digits then
		return Hit("mp5", tonumber(digits), prefix, true, false, "mp5", ManaText(digits, false))
	end
	return nil
end

local function TryLong(rest, prefix)
	local spelled = TrySpell(rest, prefix) or TryMana(rest, prefix)
	if spelled then
		return spelled
	end
	for i = 1, #LONG do
		local row = LONG[i]
		local digits = rest:match(row.pattern)
		if digits then
			return Hit(row.stat, tonumber(digits), prefix, true, row.percent, row.label)
		end
	end
	return TrySchool(rest, prefix) or TryWeapon(rest, prefix)
end

-- The returned table is reused. Read it before the next call.
function ns.MatchStatLine(text)
	if type(text) ~= "string" or text == "" then
		return nil
	end
	text = text:match("^%s*(.-)%s*$")
	if text:find("Chance on hit:", 1, true) or text:find("Use:", 1, true) == 1 then
		return nil
	end
	local prefix, rest = text:match("^(Set: )(.*)$")
	if not prefix then
		prefix = ""
		rest = text
	end
	rest = rest:gsub("^Equip: ", "")
	return TryShort(rest, prefix) or TryLong(rest, prefix)
end

function ns.FormatShort(match)
	if match.text then
		return match.prefix .. match.text
	end
	local sign = match.amount < 0 and "-" or "+"
	local number = string.format("%d", math.abs(match.amount))
	local percent = match.percent and "%" or ""
	return match.prefix .. sign .. number .. percent .. " " .. match.label
end

function ns.StripNote(text)
	return (text:gsub(" |cff808080~?%(.-%)|r$", ""))
end

function ns.PresentLine(text, shorten, showValues, snapshot)
	if type(text) ~= "string" then
		return nil
	end
	local stripped = ns.StripNote(text)
	local match = ns.MatchStatLine(stripped)
	if not match then
		return nil
	end
	local body = stripped
	local green = false
	if match.long and shorten then
		body = ns.FormatShort(match)
		green = true
	end
	if showValues then
		local note = ns.StatNote(match, snapshot)
		if note then
			body = body .. " |cff808080" .. note .. "|r"
		end
	end
	if body == text then
		return nil
	end
	return body, green
end
