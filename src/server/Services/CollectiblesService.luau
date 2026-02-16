--!strict
--[[
	Server-authoritative collectibles: config-driven positions, validation, and state.
	Does not instantiate world models; assigns one random position per item and sends to clients.
	Clients instantiate models locally; this service validates collection and persists state.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Collectibles.Config)
local RemoteNames = require(ReplicatedStorage.Shared.Collectibles.RemoteNames)
local Types = require(ReplicatedStorage.Shared.Collectibles.Types)
type ItemConfig = Types.ItemConfig
type SpawnArea = Types.SpawnArea
type PlayerCollectionState = Types.PlayerCollectionState

local Remotes = require(script.Parent.Remotes)

local COLLECT_RANGE_SQ = 12 * 12 -- 12 studs
local RATE_LIMIT_COLLECTS = 2 -- max collects per second per player

-- Item ID -> position (Vector3), computed once at startup
local itemPositions: { [string]: Vector3 } = {}
-- Item ID -> ItemConfig
local itemsById: { [string]: ItemConfig } = {}
-- Biome ID -> list of item IDs
local itemIdsByBiome: { [string]: { string } } = {}
-- Player -> last collect timestamps for rate limiting
local lastCollectTimes: { [Player]: { number } } = {}

local function randomInVolume(position: Vector3, size: Vector3): Vector3
	local half = size / 2
	return position
		+ Vector3.new(
			(half.X * 2) * (math.random() - 0.5),
			(half.Y * 2) * (math.random() - 0.5),
			(half.Z * 2) * (math.random() - 0.5)
		)
end

local function randomInSpawnArea(area: SpawnArea): Vector3
	if area.type == "point" then
		return area.position
	elseif area.type == "volume" then
		return randomInVolume(area.position, area.size)
	end
	return Vector3.zero
end

-- Returns a new 1-based array {1..n} shuffled (Fisher-Yates).
local function shuffleIndices(n: number): { number }
	local indices: { number } = {}
	for i = 1, n do
		indices[i] = i
	end
	for i = n, 2, -1 do
		local j = math.random(1, i)
		indices[i], indices[j] = indices[j], indices[i]
	end
	return indices
end

local function computeItemPositions()
	local cfg = Config.getConfig()
	-- Pass 1: build itemsById and itemIdsByBiome (no positions)
	for _, item in cfg.items do
		itemsById[item.id] = item
		if not itemIdsByBiome[item.biomeId] then
			itemIdsByBiome[item.biomeId] = {}
		end
		table.insert(itemIdsByBiome[item.biomeId], item.id)
	end
	-- Pass 2: assign one item per spawn area per biome (cycle if more items than areas)
	for _, biome in cfg.biomes do
		local areas = biome.spawnAreas
		local itemIds = biome.itemIds
		if #areas == 0 or #itemIds == 0 then
			continue
		end
		local shuffled = shuffleIndices(#areas)
		for i, itemId in ipairs(itemIds) do
			local areaIdx = shuffled[((i - 1) % #areas) + 1]
			local area = areas[areaIdx]
			itemPositions[itemId] = randomInSpawnArea(area)
		end
	end
end

local function getRemotesFolder(): Folder
	return Remotes.getFolder()
end

-- Send full state to a player (positions + their collected set) so client can render
local function sendStateToPlayer(player: Player, state: PlayerCollectionState)
	local folder = getRemotesFolder()
	local stateUpdated = folder:FindFirstChild(RemoteNames.STATE_UPDATED) :: RemoteEvent?
	if not stateUpdated then
		return
	end
	-- Payload: itemPositions (id -> {x,y,z}), collectedItemIds, config summary for UI
	local positionsTable: { [string]: { x: number, y: number, z: number } } = {}
	for id, pos in itemPositions do
		positionsTable[id] = { x = pos.X, y = pos.Y, z = pos.Z }
	end
	stateUpdated:FireClient(player, {
		itemPositions = positionsTable,
		collectedItemIds = state.collectedItemIds,
	})
end

-- Validate and process collect request; returns success, optional error
local function tryCollect(player: Player, itemId: string): (boolean, string?)
	-- Rate limit
	local times = lastCollectTimes[player]
	if not times then
		times = {}
		lastCollectTimes[player] = times
	end
	local now = os.clock()
	while #times > 0 and times[1] < now - 1 do
		table.remove(times, 1)
	end
	if #times >= RATE_LIMIT_COLLECTS then
		return false, "Rate limited"
	end

	local item = itemsById[itemId]
	if not item then
		return false, "Invalid item"
	end
	local biomeIds = itemIdsByBiome[item.biomeId]
	if not biomeIds then
		return false, "Invalid biome"
	end

	-- Distance check: use stored position (client could lie about position, but we validate range from server-known position)
	local pos = itemPositions[itemId]
	if not pos then
		return false, "No position"
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false, "No character"
	end
	local distSq = (hrp.Position - pos).Magnitude ^ 2
	if distSq > COLLECT_RANGE_SQ then
		return false, "Too far"
	end

	-- Already collected is checked by the persistence layer (it will tell us)
	table.insert(times, now)
	return true, nil
end

local CollectiblesService = {}

function CollectiblesService.getItemPositions(): { [string]: Vector3 }
	return itemPositions
end

function CollectiblesService.getItemsById(): { [string]: ItemConfig }
	return itemsById
end

function CollectiblesService.getConfig()
	return Config.getConfig()
end

-- Called by persistence when player data is loaded; sends state to client
function CollectiblesService.onPlayerDataLoaded(player: Player, state: PlayerCollectionState)
	sendStateToPlayer(player, state)
end

-- Called when a player requests collect. Persistence layer passes in current state and save callback.
function CollectiblesService.requestCollect(
	player: Player,
	itemId: string,
	getPlayerState: (Player) -> PlayerCollectionState?,
	saveAndUpdate: (Player, PlayerCollectionState) -> ()
): ()
	local folder = getRemotesFolder()
	local resultRemote = folder:FindFirstChild(RemoteNames.COLLECTION_RESULT) :: RemoteEvent?
	local ok, err = tryCollect(player, itemId)
	if not ok then
		if resultRemote then
			resultRemote:FireClient(player, { success = false, itemId = itemId, error = err or "Unknown" })
		end
		return
	end
	local state = getPlayerState(player)
	if not state then
		if resultRemote then
			resultRemote:FireClient(player, { success = false, itemId = itemId, error = "No data" })
		end
		return
	end
	for _, id in state.collectedItemIds do
		if id == itemId then
			if resultRemote then
				resultRemote:FireClient(player, { success = false, itemId = itemId, error = "Already collected" })
			end
			return
		end
	end
	-- Add to collected and persist
	local newCollected = table.clone(state.collectedItemIds)
	table.insert(newCollected, itemId)
	local newState: PlayerCollectionState = { collectedItemIds = newCollected }
	saveAndUpdate(player, newState)
	sendStateToPlayer(player, newState)
	if resultRemote then
		resultRemote:FireClient(player, { success = true, itemId = itemId })
	end
end

-- Start: compute positions, wire remotes, no world instances
function CollectiblesService.start(getPlayerState: (Player) -> PlayerCollectionState?, saveAndUpdate: (Player, PlayerCollectionState) -> ())
	computeItemPositions()
	local folder = getRemotesFolder()
	local requestCollectRemote = folder:FindFirstChild(RemoteNames.REQUEST_COLLECT) :: RemoteEvent?
	if requestCollectRemote then
		requestCollectRemote.OnServerEvent:Connect(function(player: Player, itemId: string)
			if type(itemId) ~= "string" or #itemId == 0 then
				return
			end
			-- Anti-exploit: cap length
			if #itemId > 128 then
				return
			end
			CollectiblesService.requestCollect(player, itemId, getPlayerState, saveAndUpdate)
		end)
	end
end

return CollectiblesService
