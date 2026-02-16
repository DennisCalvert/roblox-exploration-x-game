--!strict
--[[
	Data-driven configuration for biomes and collectible items.
	Designers add islands and treasure models; this config binds IDs to spawn areas and model paths.
	Adding a new biome or item does not require changing core game logic.
]]

local Types = require(script.Parent.Types)
type BiomeConfig = Types.BiomeConfig
type ItemConfig = Types.ItemConfig
type SpawnArea = Types.SpawnArea

-- Helper to build spawn volumes (position + size) for a biome area
local function volume(x: number, y: number, z: number, sx: number, sy: number, sz: number): SpawnArea
	return {
		type = "volume",
		position = Vector3.new(x, y, z),
		size = Vector3.new(sx, sy, sz),
	}
end

-- Helper to build spawn points (exact position)
local function point(x: number, y: number, z: number): SpawnArea
	return {
		type = "point",
		position = Vector3.new(x, y, z),
	}
end

-- Biome IDs (single biome: island_1; spawn volume comes from Workspace model)
local BIOME_IDS = {
	"island_1",
}

-- Number of treasure items per biome. Must match how many models exist in ReplicatedStorage.Treasures (named {biomeId}_1 .. {biomeId}_N).
local DEFAULT_ITEMS_PER_BIOME = 13
local ITEM_COUNT_BY_BIOME: { [string]: number } = {
	island_1 = 5,
}

-- Optional display names per item (item id -> name). Missing entries use "Prefix Treasure N".
local DISPLAY_NAME_OVERRIDES: { [string]: string } = {
	-- island_1_treasure_1 = "Flower",
	-- island_1_treasure_2 = "Mushroom",
	-- island_1_treasure_3 = "Rock Stone",
	-- island_1_treasure_4 = "Hapi Rock",
	-- island_1_treasure_5 = "Leaf",
}

-- Build items for one biome (count from ITEM_COUNT_BY_BIOME or DEFAULT_ITEMS_PER_BIOME)
local function itemsForBiome(biomeId: string, displayPrefix: string): { ItemConfig }
	local list: { ItemConfig } = {}
	local count = ITEM_COUNT_BY_BIOME[biomeId] or DEFAULT_ITEMS_PER_BIOME
	for i = 1, count do
		local id = biomeId .. "_treasure_" .. i
		local defaultName = displayPrefix .. " Treasure " .. i
		table.insert(list, {
			id = id,
			displayName = DISPLAY_NAME_OVERRIDES[id] or defaultName,
			biomeId = biomeId,
			modelPath = "Treasures/" .. biomeId .. "_treasure_" .. i,
		})
	end
	return list
end

-- All item configs (flat list)
local function allItems(): { ItemConfig }
	local items: { ItemConfig } = {}
	local prefixes: { [string]: string } = {
		island_1 = "Island",
	}
	for _, biomeId in BIOME_IDS do
		for _, item in itemsForBiome(biomeId, prefixes[biomeId] or biomeId) do
			table.insert(items, item)
		end
	end
	return items
end

-- Fallback spawn volume when Workspace model is missing (center from designer; default size)
local FALLBACK_SPAWN_CENTER = Vector3.new(45.468, -22.768, -84.443)
local FALLBACK_SPAWN_SIZE = Vector3.new(80, 40, 80)

-- Optional explicit spawn areas per biome. If non-empty, only these are used (safer on islands with structures).
-- Use point(x, y, z) for exact spots; volume(px, py, pz, sx, sy, sz) for boxes. Get coords from Parts in Studio.
local SPAWN_AREAS_BY_BIOME: { [string]: { SpawnArea } } = {
	island_1 = {
		point(-64, 4.903, 5),
		point(140.545, 27.365, -36.598),
		point(79, 0.703, -146),
		point(-11.142, 25.732, -133.97),
		point(62, 0.703, -9),
		point(35, 0.703, -168),
		point(148, 0.703, -116)
	},
}

-- Resolve spawn areas: use explicit SPAWN_AREAS_BY_BIOME if set; else Workspace model bounding box or fallback.
local function getSpawnAreasByBiomeId(): { [string]: { SpawnArea } }
	local result: { [string]: { SpawnArea } } = {}
	local Workspace = game:GetService("Workspace")
	for _, biomeId in BIOME_IDS do
		local spawnAreas: { SpawnArea } = {}
		local explicit = SPAWN_AREAS_BY_BIOME[biomeId]
		if explicit and #explicit > 0 then
			spawnAreas = explicit
		elseif biomeId == "island_1" then
			local model = Workspace:FindFirstChild("island_1")
			if model and model:IsA("Model") then
				local cframe, size = model:GetBoundingBox()
				table.insert(spawnAreas, volume(
					cframe.Position.X, cframe.Position.Y, cframe.Position.Z,
					size.X, size.Y, size.Z
				))
			else
				table.insert(spawnAreas, volume(
					FALLBACK_SPAWN_CENTER.X, FALLBACK_SPAWN_CENTER.Y, FALLBACK_SPAWN_CENTER.Z,
					FALLBACK_SPAWN_SIZE.X, FALLBACK_SPAWN_SIZE.Y, FALLBACK_SPAWN_SIZE.Z
				))
			end
		end
		result[biomeId] = spawnAreas
	end
	return result
end

local function getConfig(): Types.CollectiblesConfig
	local spawnAreasByBiomeId = getSpawnAreasByBiomeId()
	local biomes: { BiomeConfig } = {}
	local displayNames: { [string]: string } = {
		island_1 = "Island 1",
	}
	for _, biomeId in BIOME_IDS do
		table.insert(biomes, ({
			id = biomeId,
			displayName = displayNames[biomeId] or biomeId,
			itemIds = (function()
				local ids: { string } = {}
				for _, item in itemsForBiome(biomeId, "") do
					table.insert(ids, item.id)
				end
				return ids
			end)(),
			spawnAreas = spawnAreasByBiomeId[biomeId] or {},
		}) :: BiomeConfig)
	end
	return {
		biomes = biomes,
		items = allItems(),
	}
end

return {
	getConfig = getConfig,
}
