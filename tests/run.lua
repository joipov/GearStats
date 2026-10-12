-- Unit tests for the client-free part of Gear Stats.
--   luajit tests/run.lua
--   lua5.1 tests/run.lua

local root = (arg and arg[0] or "tests/run.lua"):match("^(.*)[/\\]tests[/\\]") or "."

local ns = {}
local function load(file)
	local chunk, err = loadfile(root .. "/" .. file)
	assert(chunk, err)
	chunk("GearStats", ns)
end

load("Patterns.lua")
load("Convert.lua")
load("Database.lua")

local passed, failed = 0, 0

local function eq(actual, expected, label)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", label or "value", tostring(expected), tostring(actual)), 2)
	end
end

local function near(actual, expected, label)
	if type(actual) ~= "number" or math.abs(actual - expected) > 0.001 then
		error(string.format("%s: expected %s, got %s", label or "value", tostring(expected), tostring(actual)), 2)
	end
end

local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
	else
		failed = failed + 1
		print("FAIL " .. name .. ": " .. tostring(err))
	end
end

local function shortened(text)
	local match = ns.MatchStatLine(text)
	if not match then
		return nil
	end
	return ns.FormatShort(match)
end

local LABELS = {
	ap = "Attack Power",
	rap = "Ranged Attack Power",
	armor = "Armor",
	spirit = "Spirit",
}

local function warrior()
	return { class = "WARRIOR", level = 60, hasMana = false, labels = LABELS }
end

local function priest(extra)
	local snapshot = {
		class = "PRIEST",
		level = 60,
		hasMana = true,
		labels = LABELS,
		atRest = 100.4,
		casting = 33.4,
		spirit = 100,
		retention = 0.33,
		approximate = false,
	}
	if extra then
		for key, value in pairs(extra) do
			snapshot[key] = value
		end
	end
	return snapshot
end

test("LoadDB fills defaults and reports a first run", function()
	local db = ns.LoadDB(nil)
	eq(ns.firstRun, true, "firstRun")
	eq(db.enabled, true, "enabled")
	eq(db.showMinimapButton, true, "showMinimapButton")
	eq(db.shorten, true, "shorten")
	eq(db.showValues, true, "showValues")
	eq(db.version, ns.DB_VERSION, "version")
	eq(db.minimapIcon.minimapPos, 220, "minimapPos")
end)

test("LoadDB reports an existing save", function()
	ns.LoadDB({})
	eq(ns.firstRun, false, "firstRun")
end)

test("LoadDB keeps an explicit disabled state", function()
	local db = ns.LoadDB({ enabled = false, shorten = false, showValues = false })
	eq(db.enabled, false, "enabled")
	eq(db.shorten, false, "shorten")
	eq(db.showValues, false, "showValues")
end)

test("LoadDB replaces a value of the wrong type", function()
	eq(ns.LoadDB({ shorten = "yes" }).shorten, true)
end)

test("LoadDB clamps the minimap position", function()
	eq(ns.LoadDB({ minimapIcon = { minimapPos = 400 } }).minimapIcon.minimapPos, 360)
end)

test("long hit line shortens", function()
	eq(shortened("Equip: Improves your chance to hit by 1%."), "+1% Hit")
end)

test("long spell hit stays distinct from hit", function()
	eq(shortened("Equip: Improves your chance to hit with spells by 1%."), "+1% Spell Hit")
end)

test("long crit and spell crit shorten", function()
	eq(shortened("Equip: Improves your chance to get a critical strike by 1%."), "+1% Crit")
	eq(shortened("Equip: Improves your chance to get a critical strike with spells by 2%."), "+2% Spell Crit")
	eq(shortened("Equip: Improves your chance to get a critical strike with Nature spells by 1%."), "+1% Nature Spell Crit")
	eq(shortened("Equip: Increases the critical effect chance of your Holy spells by 1%."), "+1% Holy Spell Crit")
end)

test("long mana per 5 shortens", function()
	eq(shortened("Equip: Restores 5 mana per 5 sec."), "+5 Mana per 5 sec")
end)

test("set prefix is kept", function()
	eq(shortened("Set: Restores 4 mana per 5 sec."), "Set: +4 Mana per 5 sec")
end)

test("healing and spell damage stay separate", function()
	eq(shortened("Equip: Increases damage and healing done by magical spells and effects by up to 12."), "+12 Spell Damage, +12 Healing")
	eq(shortened("Equip: Increases healing done by up to 48 and damage done by up to 16 for all magical spells and effects."), "+48 Healing, +16 Spell Damage")
	eq(shortened("Equip: Increases damage done by magical spells and effects by up to 16."), "+16 Spell Damage")
	eq(shortened("Equip: Increases healing done by spells and effects by up to 48."), "+48 Healing")
	eq(shortened("Equip: Increases damage done by Fire spells and effects by up to 20."), "+20 Fire Spell Damage")
end)

test("defense, dodge, weapon skill, and attack power shorten", function()
	eq(shortened("Equip: Increased Defense +3."), "+3 Defense")
	eq(shortened("Equip: Increases your chance to dodge an attack by 1%."), "+1% Dodge")
	eq(shortened("Equip: Increased Two-handed Swords +5."), "+5 Two-handed Swords Skill")
	eq(shortened("Equip: +28 Attack Power."), "+28 Attack Power")
end)

test("use and chance on hit stay as written", function()
	eq(ns.MatchStatLine("Use: Restores 5 mana per 5 sec."), nil)
	eq(ns.MatchStatLine("Chance on hit: Restores 5 mana per 5 sec."), nil)
end)

test("a short strength line is recognized and not rewritten", function()
	local match = ns.MatchStatLine("+6 Strength")
	eq(match.stat, "strength")
	eq(match.amount, 6)
	eq(match.long, false)
	eq(ns.FormatShort(match), "+6 Strength")
end)

test("warrior strength is attack power", function()
	eq(ns.AttributeNote("strength", 6, "WARRIOR", LABELS, 60), "(12 Attack Power)")
	eq(ns.AttributeNote("strength", -6, "WARRIOR", LABELS, 60), "(-12 Attack Power)")
end)

test("priest strength is one attack power per point", function()
	eq(ns.AttributeNote("strength", 6, "PRIEST", LABELS, 60), "(6 Attack Power)")
end)

test("hunter agility is melee and ranged attack power and armor", function()
	eq(
		ns.AttributeNote("agility", 10, "HUNTER", LABELS, 10),
		"(10 Attack Power, 20 Ranged Attack Power, 20 Armor)"
	)
end)

test("warrior agility is ranged attack power and armor", function()
	eq(ns.AttributeNote("agility", 10, "WARRIOR", LABELS, 60), "(20 Ranged Attack Power, 20 Armor)")
end)

test("paladin agility is armor", function()
	eq(ns.AttributeNote("agility", 10, "PALADIN", LABELS, 30), "(20 Armor)")
end)

test("paladin crit checkpoints are not guessed", function()
	-- Forever's +10 Agility checks: 2.15, 1.72, 1.229, 0.935, 0.506.
	-- Nil means the number is left off. A filled-in table has to hit these.
	local checks = {
		{ level = 1, expected = 2.15 },
		{ level = 10, expected = 1.72 },
		{ level = 20, expected = 1.229 },
		{ level = 30, expected = 0.935 },
		{ level = 60, expected = 0.506 },
	}
	for i = 1, #checks do
		local got = ns.CritPercent("PALADIN", checks[i].level, 10)
		if got ~= nil then
			near(got, checks[i].expected, "level " .. checks[i].level)
		end
	end
	eq(ns.AttributeNote("agility", 10, "PALADIN", LABELS, 10):find("Crit", 1, true), nil)
end)

test("mana per 5 at 33 percent retention", function()
	local atRest, whileCasting, none = ns.SpiritForMP5(5, 100.4, 33.4, 100, 0.33)
	near(atRest, 1, "at rest")
	near(whileCasting, 1 / 0.33, "while casting")
	eq(none, false, "none")
	eq(ns.SpiritNote(5, priest()), "(1 Spirit at rest, 3 Spirit while casting)")
end)

test("mana per 5 with no retention while casting", function()
	local atRest, whileCasting, none = ns.SpiritForMP5(5, 100.4, 0.4, 100, 0)
	near(atRest, 1, "at rest")
	eq(whileCasting, nil, "while casting")
	eq(none, true, "none")
	eq(
		ns.SpiritNote(5, priest({ casting = 0.4, retention = 0 })),
		"(1 Spirit at rest, Spirit adds nothing while casting)"
	)
end)

test("full retention or a missing rate omits the spirit note", function()
	eq(ns.SpiritForMP5(5, 100, 100, 100, 1), nil)
	eq(ns.SpiritForMP5(5, nil, 1, 100, 0), nil)
	eq(ns.SpiritForMP5(5, 10, 1, 0, 0), nil)
	local missing = priest()
	missing.atRest = nil
	eq(ns.SpiritNote(5, missing), nil)
	eq(ns.SpiritNote(5, warrior()), nil)
end)

test("a stale regen reading is marked", function()
	eq(
		ns.SpiritNote(5, priest({ approximate = true })),
		"~(1 Spirit at rest, 3 Spirit while casting)"
	)
end)

test("present line shortens, notes, and is idempotent", function()
	local snapshot = warrior()
	local text, green = ns.PresentLine("+6 Strength", true, true, snapshot)
	eq(text, "+6 Strength |cff808080(12 Attack Power)|r")
	eq(green, false)
	eq(ns.PresentLine(text, true, true, snapshot), nil)

	local short, shortGreen = ns.PresentLine("Equip: Restores 5 mana per 5 sec.", true, true, priest())
	eq(short, "+5 Mana per 5 sec |cff808080(1 Spirit at rest, 3 Spirit while casting)|r")
	eq(shortGreen, true)
	eq(ns.PresentLine(short, true, true, priest()), nil)
end)

test("numbers drop a trailing zero", function()
	eq(ns.FormatNumber(3), "3")
	eq(ns.FormatNumber(3.04), "3")
	eq(ns.FormatNumber(3.06), "3.1")
	eq(ns.FormatNumber(-12), "-12")
end)

if failed > 0 then
	print(string.format("%d failed, %d passed", failed, passed))
	os.exit(1)
end
print(string.format("%d passed", passed))
