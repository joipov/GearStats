local _, ns = ...

-- Item tooltips: replace a long stat sentence in place, and append what that
-- stat is worth. Healing and spell damage from one sentence become two real
-- lines. A newline inside one line is taller than the tooltip's own row gap,
-- which left extra space above the next stat.

local issecretvalue = issecretvalue
local canaccessvalue = canaccessvalue

-- Show() lays the tooltip out again, which re-enters this post-call.
local busy = setmetatable({}, { __mode = "k" })

-- Reused so a hover does not allocate a row table.
local rows = {}
local rowCount = 0

local function SecretBlocked(value)
	return issecretvalue(value) and not canaccessvalue(value)
end

local function NamedString(tooltip, index, side)
	if SecretBlocked(index) then
		return nil
	end
	local key = side .. index
	local fs = tooltip[key]
	if fs then
		return fs
	end
	local name = tooltip:GetName()
	if type(name) ~= "string" or name == "" or SecretBlocked(name) then
		return nil
	end
	return _G[name .. key]
end

local function FontString(tooltip, index)
	return NamedString(tooltip, index, "TextLeft")
end

local function RightString(tooltip, index)
	return NamedString(tooltip, index, "TextRight")
end

local function ColorOf(fs)
	if not fs then
		return nil, nil, nil
	end
	local r, g, b = fs:GetTextColor()
	if SecretBlocked(r) or SecretBlocked(g) or SecretBlocked(b) then
		return nil, nil, nil
	end
	return r, g, b
end

local function Push(text, r, g, b, right, rr, rg, rb)
	rowCount = rowCount + 1
	local row = rows[rowCount]
	if not row then
		row = {}
		rows[rowCount] = row
	end
	row.text = text
	row.r, row.g, row.b = r, g, b
	row.right = right
	row.rr, row.rg, row.rb = rr, rg, rb
end

-- Healing Power is the upper line when an item also has Spell Damage.
local spellSlots = {}
local spellKinds = {}
local spellOrdered = {}

local function SpellRowKind(text)
	if type(text) ~= "string" then
		return nil
	end
	local healing = text:find("Healing Power", 1, true) ~= nil
	local damage = text:find("Spell Damage", 1, true) ~= nil
	if healing and not damage then
		return "healing"
	end
	if damage and not healing then
		return "damage"
	end
	return nil
end

-- Moves healing rows into the higher spell slots and spell damage into the
-- lower ones. Other rows stay put. Returns whether the order changed.
function ns.PlaceHealingAboveDamage(rowList, count)
	if type(count) ~= "number" or count < 1 then
		return false
	end
	local slotCount = 0
	for i = 1, count do
		local row = rowList[i]
		local kind = row and SpellRowKind(row.text)
		if kind then
			slotCount = slotCount + 1
			spellSlots[slotCount] = i
			spellKinds[slotCount] = kind
		end
	end
	for i = slotCount + 1, #spellSlots do
		spellSlots[i] = nil
		spellKinds[i] = nil
	end
	local seenDamage = false
	local disordered = false
	for i = 1, slotCount do
		if spellKinds[i] == "damage" then
			seenDamage = true
		elseif seenDamage then
			disordered = true
			break
		end
	end
	if not disordered then
		return false
	end
	local placed = 0
	for i = 1, slotCount do
		if spellKinds[i] == "healing" then
			placed = placed + 1
			spellOrdered[placed] = rowList[spellSlots[i]]
		end
	end
	for i = 1, slotCount do
		if spellKinds[i] == "damage" then
			placed = placed + 1
			spellOrdered[placed] = rowList[spellSlots[i]]
		end
	end
	for i = 1, slotCount do
		rowList[spellSlots[i]] = spellOrdered[i]
		spellOrdered[i] = nil
	end
	return true
end

local function WriteRows(tooltip)
	while tooltip:NumLines() < rowCount do
		tooltip:AddDoubleLine(" ", " ")
	end
	for i = 1, rowCount do
		local row = rows[i]
		local fs = FontString(tooltip, i)
		if fs then
			fs:SetText(row.text)
			if row.r then
				fs:SetTextColor(row.r, row.g, row.b)
			end
		end
		local right = RightString(tooltip, i)
		if right then
			right:SetText(row.right or "")
			if row.right == nil or row.right == "" then
				right:Hide()
			else
				right:Show()
				if row.rr then
					right:SetTextColor(row.rr, row.rg, row.rb)
				end
			end
		end
	end
end

function ns.OnItemTooltip(tooltip)
	local db = ns.db
	if not db or not db.enabled or not tooltip or busy[tooltip] then
		return
	end
	if not db.shorten and not db.showValues then
		return
	end
	local count = tooltip:NumLines()
	if type(count) ~= "number" or SecretBlocked(count) or count < 1 then
		return
	end
	local snapshot = ns.snapshot
	rowCount = 0
	local changed = false
	for i = 1, count do
		local fs = FontString(tooltip, i)
		if not fs then
			return
		end
		local text = fs:GetText()
		if type(text) ~= "string" or SecretBlocked(text) then
			return
		end
		local rightFs = RightString(tooltip, i)
		local right = rightFs and rightFs:GetText() or nil
		if SecretBlocked(right) then
			return
		end
		local r, g, b = ColorOf(fs)
		local rr, rg, rb = ColorOf(rightFs)
		local newText, green = ns.PresentLine(text, db.shorten, db.showValues, snapshot)
		local shown = newText or text
		if newText then
			changed = true
		end
		local first, second = shown:match("^(.-)\n(.*)$")
		if first and green then
			Push(first, 0, 1, 0, right, rr, rg, rb)
			Push(second, 0, 1, 0, nil, nil, nil, nil)
		elseif green then
			Push(shown, 0, 1, 0, right, rr, rg, rb)
		else
			Push(shown, r, g, b, right, rr, rg, rb)
		end
	end
	if ns.PlaceHealingAboveDamage(rows, rowCount) then
		changed = true
	end
	if not changed then
		return
	end
	busy[tooltip] = true
	WriteRows(tooltip)
	tooltip:Show()
	busy[tooltip] = nil
end
