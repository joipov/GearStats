local _, ns = ...

-- One reading of class, level, regen, and how much Spirit regen casting keeps.
-- Refreshed from events, never from a tooltip pass. In combat the client
-- often hides these numbers; the last readable reading is kept.

local issecretvalue = issecretvalue
local canaccessvalue = canaccessvalue
local issecrettable = issecrettable
local canaccesstable = canaccesstable

local MANA = {
	HUNTER = true,
	PALADIN = true,
	PRIEST = true,
	SHAMAN = true,
	MAGE = true,
	WARLOCK = true,
	DRUID = true,
}

-- Classic ranks. The percent is read from the spell text, not from these ids.
-- A wrong id simply is not known. Forever talents that are passive spells are
-- picked up from the spellbook by the same phrase.
local PASSIVE_SPELLS = {
	14521, 14776, 14777,
	18463, 18464, 18465,
	17106, 17107, 17108,
}

local RETENTION = "(%d+)%% of your [Mm]ana regeneration"

local function SecretBlocked(value)
	return issecretvalue(value) and not canaccessvalue(value)
end

local function TableBlocked(value)
	return issecrettable(value) and not canaccesstable(value)
end

local function ReadableNumber(value)
	if type(value) ~= "number" or SecretBlocked(value) then
		return nil
	end
	return value
end

local function Label(key, fallback)
	local value = _G[key]
	if type(value) == "string" and value ~= "" and not SecretBlocked(value) then
		return value
	end
	return fallback
end

-- Returns the percent, and whether the text was hidden.
local function PercentIn(description)
	if SecretBlocked(description) then
		return nil, true
	end
	if type(description) ~= "string" then
		return nil, false
	end
	local pct = description:match(RETENTION)
	if not pct then
		return nil, false
	end
	return tonumber(pct), false
end

local function Consider(description, best)
	local pct, secret = PercentIn(description)
	if secret then
		return best, true
	end
	if pct and (not best or pct > best) then
		return pct, false
	end
	return best, false
end

local function ScanPassives()
	local best = nil
	local C_Spell = C_Spell
	for i = 1, #PASSIVE_SPELLS do
		local spellID = PASSIVE_SPELLS[i]
		if IsPlayerSpell(spellID) then
			local blocked
			best, blocked = Consider(C_Spell.GetSpellDescription(spellID), best)
			if blocked then
				return nil, false
			end
		end
	end

	local lines = C_SpellBook.GetNumSpellBookSkillLines()
	if type(lines) ~= "number" or SecretBlocked(lines) then
		return nil, false
	end
	for line = 1, lines do
		local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
		if TableBlocked(info) then
			return nil, false
		end
		if type(info) == "table" then
			local offset = info.itemIndexOffset
			local count = info.numSpellBookItems
			if type(offset) == "number" and type(count) == "number" then
				for index = offset + 1, offset + count do
					local item = C_SpellBook.GetSpellBookItemInfo(index, Enum.SpellBookSpellBank.Player)
					if type(item) == "table" and not TableBlocked(item) then
						local spellID = item.spellID
						if type(spellID) == "number" and not SecretBlocked(spellID) and C_Spell.IsSpellPassive(spellID) then
							local blocked
							best, blocked = Consider(C_Spell.GetSpellDescription(spellID), best)
							if blocked then
								return nil, false
							end
						end
					end
				end
			end
		end
	end
	return best or 0, true
end

local function ScanAuras()
	local best = nil
	local C_Spell = C_Spell
	for index = 1, 40 do
		local aura = C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL")
		if not aura then
			break
		end
		if TableBlocked(aura) then
			return nil, false
		end
		local spellID = aura.spellId
		if SecretBlocked(spellID) then
			return nil, false
		end
		local blocked
		best, blocked = Consider(C_Spell.GetSpellDescription(spellID), best)
		if blocked then
			return nil, false
		end
	end
	return best or 0, true
end

function ns.RefreshSnapshot()
	local snap = ns.snapshot
	if not snap then
		snap = {}
		ns.snapshot = snap
	end
	if not snap.labels then
		snap.labels = {
			-- Forever's ATTACK_POWER string is "Power".
			ap = "Attack Power",
			rap = "Ranged Attack Power",
			armor = Label("ARMOR", "Armor"),
			spirit = Label("SPELL_STAT5_NAME", "Spirit"),
		}
	end

	local _, token = UnitClass("player")
	if type(token) == "string" and not SecretBlocked(token) then
		snap.class = token
	end
	local level = UnitLevel("player")
	if type(level) == "number" and not SecretBlocked(level) then
		snap.level = level
	end

	if not MANA[snap.class] then
		snap.hasMana = false
		snap.approximate = false
		return
	end
	snap.hasMana = true

	local regenFresh = false
	local atRest, casting = GetManaRegen()
	local spirit = select(2, UnitStat("player", 5))
	local atRestN = ReadableNumber(atRest)
	local castingN = ReadableNumber(casting)
	local spiritN = ReadableNumber(spirit)
	if atRestN and castingN and spiritN then
		snap.atRest = atRestN
		snap.casting = castingN
		snap.spirit = spiritN
		regenFresh = true
	end

	local retentionFresh = false
	if ns.talentsDirty then
		local pct, ok = ScanPassives()
		if ok then
			snap.passivePercent = pct
			ns.talentsDirty = false
		end
	end
	local auraPct, auraOk = ScanAuras()
	if auraOk then
		snap.auraPercent = auraPct
	end
	if snap.passivePercent ~= nil and snap.auraPercent ~= nil then
		snap.retention = math.max(snap.passivePercent, snap.auraPercent) / 100
		retentionFresh = not ns.talentsDirty and auraOk
	end

	snap.approximate = not (regenFresh and retentionFresh) and snap.atRest ~= nil and snap.retention ~= nil
end
