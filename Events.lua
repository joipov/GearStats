local ADDON_NAME, ns = ...

-- The addon's single event frame and the tooltip post-call. Snapshot reads
-- are coalesced onto one timer.

local C_Timer = C_Timer

local eventFrame = CreateFrame("Frame")

local FEATURE_EVENTS = {
	"PLAYER_ENTERING_WORLD",
	{ "UNIT_AURA", "player" },
	{ "UNIT_STATS", "player" },
	"PLAYER_EQUIPMENT_CHANGED",
	"PLAYER_LEVEL_UP",
	"PLAYER_TALENT_UPDATE",
	"TRAIT_CONFIG_UPDATED",
	"PLAYER_REGEN_ENABLED",
}

function ns.SetEventsRegistered(events, active)
	for i = 1, #events do
		local entry = events[i]
		if type(entry) == "table" then
			if active then
				eventFrame:RegisterUnitEvent(entry[1], entry[2])
			else
				eventFrame:UnregisterEvent(entry[1])
			end
		elseif active then
			eventFrame:RegisterEvent(entry)
		else
			eventFrame:UnregisterEvent(entry)
		end
	end
end

local function Print(message)
	print("|cff8b5cf6Joipov|r Gear Stats: " .. tostring(message or ""))
end

ns.Print = Print

function ns.Debug(...)
	if not (ns.db and ns.db.debug) then
		return
	end
	local count = select("#", ...)
	local parts = {}
	for i = 1, count do
		parts[i] = tostring(select(i, ...))
	end
	Print(table.concat(parts, " "))
end

function ns.Welcome()
	local title = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or "Gear Stats"
	local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"
	print(string.format("|cff8b5cf6Joipov|r %s (|cff22d3eev%s|r). Type |cffffffff/gs|r to open settings.", title, version))
end

local refreshQueued = false

local function RunRefresh()
	refreshQueued = false
	if ns.db and ns.db.enabled then
		ns.RefreshSnapshot()
	end
end

local function QueueRefresh()
	if refreshQueued then
		return
	end
	refreshQueued = true
	C_Timer.After(0, RunRefresh)
end

local function MarkTalentsDirty()
	ns.talentsDirty = true
	QueueRefresh()
end

function ns.SetEnabled()
	local on = ns.db and ns.db.enabled
	ns.SetEventsRegistered(FEATURE_EVENTS, on)
	if on then
		ns.talentsDirty = true
		ns.RefreshSnapshot()
	end
end

local handlers = {}

function handlers.ADDON_LOADED(name)
	if name ~= ADDON_NAME then
		return
	end
	eventFrame:UnregisterEvent("ADDON_LOADED")
	_G.GearStatsDB = ns.LoadDB(_G.GearStatsDB)
	ns.db = _G.GearStatsDB
	ns.InitOptions()
	eventFrame:RegisterEvent("PLAYER_LOGIN")
end

function handlers.PLAYER_LOGIN()
	ns.CreateMinimapButton()
	ns.Welcome()
	ns.SetEnabled()
end

handlers.PLAYER_ENTERING_WORLD = MarkTalentsDirty
handlers.PLAYER_LEVEL_UP = MarkTalentsDirty
handlers.PLAYER_TALENT_UPDATE = MarkTalentsDirty
handlers.TRAIT_CONFIG_UPDATED = MarkTalentsDirty

handlers.UNIT_AURA = QueueRefresh
handlers.UNIT_STATS = QueueRefresh
handlers.PLAYER_EQUIPMENT_CHANGED = QueueRefresh
handlers.PLAYER_REGEN_ENABLED = QueueRefresh

eventFrame:SetScript("OnEvent", function(_, event, ...)
	local handler = handlers[event]
	if handler then
		handler(...)
	end
end)
eventFrame:RegisterEvent("ADDON_LOADED")

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ns.OnItemTooltip)
if Enum.TooltipDataType.Spell then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip)
		if ns.TooltipHasGearLine(tooltip) then
			ns.OnItemTooltip(tooltip)
		end
	end)
end
