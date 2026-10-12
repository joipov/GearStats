local _, ns = ...

-- Settings panel, in the Blizzard Settings API.

local Settings = Settings

function ns.OpenSettings()
	if not ns.settingsCategory then
		ns.InitOptions()
	end
	if not ns.settingsCategory then
		ns.Print("Couldn't open settings.")
		return
	end
	Settings.OpenToCategory(ns.settingsCategory:GetID())
end

function ns.InitOptions()
	if ns.settingsCategory then
		return
	end
	local category = Settings.RegisterVerticalLayoutCategory("Gear Stats")
	ns.settingsCategory = category

	local enableSetting = Settings.RegisterAddOnSetting(
		category,
		"GS_ENABLED",
		"enabled",
		ns.db,
		Settings.VarType.Boolean,
		"Enable Gear Stats",
		ns.defaults.enabled
	)
	enableSetting:SetValueChangedCallback(function()
		ns.SetEnabled()
	end)
	local enableCheckbox = Settings.CreateCheckbox(
		category,
		enableSetting,
		"Shortens stat lines on items and shows what Strength, Agility, and mana per 5 seconds are worth."
	)

	local minimapSetting = Settings.RegisterAddOnSetting(
		category,
		"GS_SHOW_MINIMAP",
		"showMinimapButton",
		ns.db,
		Settings.VarType.Boolean,
		"Minimap button",
		ns.defaults.showMinimapButton
	)
	minimapSetting:SetValueChangedCallback(function()
		ns.UpdateMinimapButton()
	end)
	local minimapCheckbox = Settings.CreateCheckbox(
		category,
		minimapSetting,
		"Button on the minimap. Opens settings. Ellesmere puts it with the other addon buttons."
	)

	local shortenSetting = Settings.RegisterAddOnSetting(
		category,
		"GS_SHORTEN",
		"shorten",
		ns.db,
		Settings.VarType.Boolean,
		"Shorten stat lines",
		ns.defaults.shorten
	)
	local shortenCheckbox = Settings.CreateCheckbox(
		category,
		shortenSetting,
		"Turns a long stat sentence into a short line."
	)

	local valuesSetting = Settings.RegisterAddOnSetting(
		category,
		"GS_SHOW_VALUES",
		"showValues",
		ns.db,
		Settings.VarType.Boolean,
		"Show stat values",
		ns.defaults.showValues
	)
	local valuesCheckbox = Settings.CreateCheckbox(
		category,
		valuesSetting,
		"Shows attack power and armor for Strength and Agility, and the Spirit behind mana per 5 seconds."
	)

	local function Enabled()
		return enableSetting:GetValue()
	end
	minimapCheckbox:SetParentInitializer(enableCheckbox, Enabled)
	shortenCheckbox:SetParentInitializer(enableCheckbox, Enabled)
	valuesCheckbox:SetParentInitializer(enableCheckbox, Enabled)

	Settings.RegisterAddOnCategory(category)
end

function _G.GearStats_OnAddonCompartmentClick()
	ns.OpenSettings()
end

function _G.GearStats_OnAddonCompartmentEnter(_, menuButton)
	GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
	GameTooltip:AddLine("Gear Stats")
	GameTooltip:AddLine("Click for settings.", 1, 1, 1)
	GameTooltip:Show()
end

function _G.GearStats_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end

_G.SLASH_GEARSTATS1 = "/gs"
_G.SLASH_GEARSTATS2 = "/gearstats"
_G.SlashCmdList.GEARSTATS = ns.OpenSettings
