local _, ns = ...

-- What a point of a stat becomes for one class. No WoW calls: the tests load
-- this file on its own. Cat Form uses its own Agility conversion, which is
-- not in the class table, so a druid sees the class baseline either way.

local AP = {
	WARRIOR = { str = 2, agiMelee = 0, agiRanged = 2 },
	PALADIN = { str = 2, agiMelee = 0, agiRanged = 0 },
	HUNTER = { str = 1, agiMelee = 1, agiRanged = 2 },
	ROGUE = { str = 1, agiMelee = 1, agiRanged = 2 },
	PRIEST = { str = 1, agiMelee = 0, agiRanged = 0 },
	SHAMAN = { str = 2, agiMelee = 0, agiRanged = 0 },
	MAGE = { str = 1, agiMelee = 0, agiRanged = 0 },
	WARLOCK = { str = 1, agiMelee = 0, agiRanged = 0 },
	DRUID = { str = 2, agiMelee = 0, agiRanged = 0 },
}

local ARMOR_PER_AGI = 2

local DEFAULT_LABELS = {
	ap = "Attack Power",
	rap = "Ranged Attack Power",
	armor = "Armor",
	spirit = "Spirit",
}

-- Reused so a tooltip pass does not allocate a table per line.
local bits = {}

local function FormatNumber(value)
	local negative = value < 0
	local rounded = math.floor(math.abs(value) * 10 + 0.5) / 10
	local text
	if rounded == math.floor(rounded) then
		text = string.format("%d", rounded)
	else
		text = string.format("%.1f", rounded)
	end
	if negative and rounded ~= 0 then
		return "-" .. text
	end
	return text
end

ns.FormatNumber = FormatNumber

-- Crit from Agility is a class-and-level coefficient in PlayerExpectedStat.
-- The public per-level tables miss Forever's paladin checks for +10 Agility
-- (2.15% at 1, 1.72% at 10, 1.229% at 20, 0.935% at 30, 0.506% at 60), so
-- nothing is shown until a table matches those points. No interpolation.
function ns.CritPercent(classToken, level, amount)
	if type(classToken) ~= "string" or type(level) ~= "number" or type(amount) ~= "number" then
		return nil
	end
	return nil
end

local function LabelsOf(snapshot)
	if snapshot and snapshot.labels then
		return snapshot.labels
	end
	return DEFAULT_LABELS
end

local noteCount = 0

local function AddBit(value, label)
	if value ~= 0 and label then
		noteCount = noteCount + 1
		bits[noteCount] = FormatNumber(value) .. " " .. label
	end
end

local function Join()
	for i = noteCount + 1, #bits do
		bits[i] = nil
	end
	if noteCount == 0 then
		return nil
	end
	return "(" .. table.concat(bits, ", ") .. ")"
end

function ns.AttributeNote(stat, amount, classToken, labels, level)
	local row = AP[classToken]
	if not row or type(amount) ~= "number" or amount == 0 then
		return nil
	end
	labels = labels or DEFAULT_LABELS
	noteCount = 0
	if stat == "strength" then
		AddBit(amount * row.str, labels.ap)
	elseif stat == "agility" then
		AddBit(amount * row.agiMelee, labels.ap)
		AddBit(amount * row.agiRanged, labels.rap)
		local crit = ns.CritPercent(classToken, level, amount)
		if crit then
			noteCount = noteCount + 1
			bits[noteCount] = FormatNumber(crit) .. "% Crit"
		end
		AddBit(amount * ARMOR_PER_AGI, labels.armor)
	else
		return nil
	end
	return Join()
end

-- Mana per 5 seconds from one point of Spirit, from the character's own
-- regen. Nil when flat mana and Spirit cannot be split.
local function MP5PerSpirit(atRest, casting, spirit, retention)
	if type(atRest) ~= "number" or type(casting) ~= "number" then
		return nil
	end
	if type(spirit) ~= "number" or spirit <= 0 then
		return nil
	end
	if type(retention) ~= "number" or retention < 0 or retention >= 1 then
		return nil
	end
	local spiritPerSec = (atRest - casting) / (1 - retention)
	if spiritPerSec <= 0 then
		return nil
	end
	local per = spiritPerSec * 5 / spirit
	if per <= 0 then
		return nil
	end
	return per
end

-- atRest and casting are mana per second from GetManaRegen. retention is the
-- share of Spirit regen kept while casting, 0 to 1. Returns the Spirit that
-- matches itemMP5 at rest, the Spirit that matches it while casting, and
-- whether Spirit adds nothing while casting. Nil when the rate cannot be split.
function ns.SpiritForMP5(itemMP5, atRest, casting, spirit, retention)
	if type(itemMP5) ~= "number" or itemMP5 == 0 then
		return nil
	end
	local per = MP5PerSpirit(atRest, casting, spirit, retention)
	if not per then
		return nil
	end
	local atRestSpirit = itemMP5 / per
	if retention == 0 then
		return atRestSpirit, nil, true
	end
	return atRestSpirit, atRestSpirit / retention, false
end

-- The mana per 5 seconds one item's Spirit is worth, at rest and while casting.
function ns.MP5ForSpirit(itemSpirit, atRest, casting, spirit, retention)
	if type(itemSpirit) ~= "number" or itemSpirit == 0 then
		return nil
	end
	local per = MP5PerSpirit(atRest, casting, spirit, retention)
	if not per then
		return nil
	end
	local atRestMP5 = itemSpirit * per
	if retention == 0 then
		return atRestMP5, nil, true
	end
	return atRestMP5, atRestMP5 * retention, false
end

function ns.SpiritNote(itemMP5, snapshot)
	if not snapshot or not snapshot.hasMana then
		return nil
	end
	local atRest, whileCasting, none = ns.SpiritForMP5(
		itemMP5,
		snapshot.atRest,
		snapshot.casting,
		snapshot.spirit,
		snapshot.retention
	)
	if not atRest then
		return nil
	end
	local spirit = LabelsOf(snapshot).spirit or "Spirit"
	local tilde = snapshot.approximate and "~" or ""
	local second
	if none then
		second = spirit .. " adds nothing while casting"
	else
		second = FormatNumber(whileCasting) .. " " .. spirit .. " while casting"
	end
	return tilde .. "(" .. FormatNumber(atRest) .. " " .. spirit .. " at rest, " .. second .. ")"
end

function ns.ManaNote(itemSpirit, snapshot)
	if not snapshot or not snapshot.hasMana then
		return nil
	end
	local atRest, whileCasting, none = ns.MP5ForSpirit(
		itemSpirit,
		snapshot.atRest,
		snapshot.casting,
		snapshot.spirit,
		snapshot.retention
	)
	if not atRest then
		return nil
	end
	local castingText = none and "0" or FormatNumber(whileCasting)
	local tilde = snapshot.approximate and "~" or ""
	return tilde .. "(" .. FormatNumber(atRest) .. " / " .. castingText .. " mp5)"
end

function ns.StatNote(match, snapshot)
	if not match or not snapshot then
		return nil
	end
	if match.stat == "strength" or match.stat == "agility" then
		return ns.AttributeNote(match.stat, match.amount, snapshot.class, LabelsOf(snapshot), snapshot.level)
	end
	if match.stat == "mp5" then
		return ns.SpiritNote(match.amount, snapshot)
	end
	if match.stat == "spirit" then
		return ns.ManaNote(match.amount, snapshot)
	end
	return nil
end
