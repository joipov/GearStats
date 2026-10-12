local _, ns = ...

-- Item tooltips: replace a long stat sentence in place, and append what that
-- stat is worth. The tooltip is not rebuilt.

local issecretvalue = issecretvalue
local canaccessvalue = canaccessvalue

local function SecretBlocked(value)
	return issecretvalue(value) and not canaccessvalue(value)
end

local function FontString(tooltip, index)
	if SecretBlocked(index) then
		return nil
	end
	local fs = tooltip["TextLeft" .. index]
	if fs then
		return fs
	end
	local name = tooltip:GetName()
	if type(name) ~= "string" or name == "" or SecretBlocked(name) then
		return nil
	end
	return _G[name .. "TextLeft" .. index]
end

function ns.OnItemTooltip(tooltip)
	local db = ns.db
	if not db or not db.enabled or not tooltip then
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
	for i = 1, count do
		local fs = FontString(tooltip, i)
		if fs then
			local text = fs:GetText()
			if type(text) == "string" and not SecretBlocked(text) then
				local newText, green = ns.PresentLine(text, db.shorten, db.showValues, snapshot)
				if newText then
					fs:SetText(newText)
					if green then
						fs:SetTextColor(0, 1, 0)
					end
				end
			end
		end
	end
end
