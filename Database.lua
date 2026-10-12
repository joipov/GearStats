local _, ns = ...

-- Saved variables: defaults, migrations, validation. Plain Lua, so the tests
-- can load it without a client.

local DB_VERSION = 1
local MINIMAP_POS = 220

-- Scalars only. Tables are built fresh in EnsureTables.
local defaults = {
	enabled = true,
	showMinimapButton = true,
	shorten = true,
	showValues = true,
}

local function ClampNumber(value, lo, hi, fallback)
	if type(value) ~= "number" or value ~= value then
		return fallback
	end
	if value < lo then
		return lo
	end
	if value > hi then
		return hi
	end
	return value
end

local function EnsureTables(db)
	if type(db.minimapIcon) ~= "table" then
		db.minimapIcon = {}
	end
	db.minimapIcon.minimapPos = ClampNumber(db.minimapIcon.minimapPos, 0, 360, MINIMAP_POS)
end

local function CopyDefaults(db)
	for key, value in pairs(defaults) do
		if type(db[key]) ~= type(value) then
			db[key] = value
		end
	end
	EnsureTables(db)
end

local function Validate(db)
	db.minimapIcon.minimapPos = ClampNumber(db.minimapIcon.minimapPos, 0, 360, MINIMAP_POS)
end

local function MigrateDB(db)
	db.version = DB_VERSION
end

function ns.LoadDB(saved)
	ns.firstRun = type(saved) ~= "table"
	local db = ns.firstRun and {} or saved
	MigrateDB(db)
	CopyDefaults(db)
	Validate(db)
	return db
end

ns.defaults = defaults
ns.DB_VERSION = DB_VERSION
