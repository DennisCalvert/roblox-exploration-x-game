--!strict
--[[
	Client collectibles: receives state from server, spawns local models for uncollected items,
	handles proximity and collect requests, updates local state for UI.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Collectibles.Config)
local RemoteNames = require(ReplicatedStorage.Shared.Collectibles.RemoteNames)
local Types = require(ReplicatedStorage.Shared.Collectibles.Types)
type PlayerCollectionState = Types.PlayerCollectionState
type BiomeProgress = Types.BiomeProgress

local COLLECT_RANGE = 10

-- Current state from server (positions + our collected set)
local itemPositions: { [string]: Vector3 } = {}
local collectedItemIds: { [string]: boolean } = {} -- set for fast lookup
local worldModels: { [string]: Model } = {} -- itemId -> cloned model in workspace

-- UI / external: get current collection state and progress
local stateListeners: { (PlayerCollectionState) -> () } = {}
local config = Config.getConfig()

local function getState(): PlayerCollectionState
	local list: { string } = {}
	for id in collectedItemIds do
		table.insert(list, id)
	end
	return { collectedItemIds = list }
end

local function getBiomeProgress(): { BiomeProgress }
	local result: { BiomeProgress } = {}
	for _, biome in config.biomes do
		local collected: { string } = {}
		for _, id in biome.itemIds do
			if collectedItemIds[id] then
				table.insert(collected, id)
			end
		end
		table.insert(result, {
			biomeId = biome.id,
			collectedCount = #collected,
			totalCount = #biome.itemIds,
			collectedItemIds = collected,
		})
	end
	return result
end

-- Expose for UI: real-time state and biome progress
local CollectiblesController = {
	getState = getState,
	getBiomeProgress = getBiomeProgress,
	getConfig = function()
		return config
	end,
	-- Subscribe to state changes (e.g. for UI)
	subscribeToState = function(callback: (PlayerCollectionState) -> ())
		table.insert(stateListeners, callback)
		callback(getState())
	end,
}

local function getRemotesFolder(): Folder?
	local folder = ReplicatedStorage:WaitForChild("CollectiblesRemotes", 10) :: Folder?
	return folder
end

local function requestCollect(itemId: string)
	local folder = getRemotesFolder()
	if not folder then
		return
	end
	local remote = folder:FindFirstChild(RemoteNames.REQUEST_COLLECT) :: RemoteEvent?
	if remote then
		remote:FireServer(itemId)
	end
end

local function getModelForItem(itemId: string): Model?
	-- Resolve model path from config
	local items = config.items
	local modelPath: string? = nil
	for _, item in items do
		if item.id == itemId then
			modelPath = item.modelPath
			break
		end
	end
	if not modelPath then
		return nil
	end
	local parts = string.split(modelPath, "/")
	local current: Instance = ReplicatedStorage
	for _, name in parts do
		current = current:WaitForChild(name, 5) :: Instance
		if not current then
			return nil
		end
	end
	if current:IsA("Model") then
		return current :: Model
	end
	if current:IsA("BasePart") then
		local model = Instance.new("Model")
		model.Name = itemId
		local clone = (current :: BasePart):Clone()
		clone.Parent = model
		return model
	end
	return nil
end

local function addProximityPrompt(model: Model, itemId: string)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CollectPrompt"
	prompt.ActionText = "Collect"
	prompt.ObjectText = itemId
	prompt.MaxActivationDistance = COLLECT_RANGE
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function()
		requestCollect(itemId)
	end)
	local target = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if target then
		prompt.Parent = target
	else
		prompt.Parent = model
	end
end

local function spawnLocalModel(itemId: string, position: Vector3)
	if worldModels[itemId] then
		return
	end
	local template = getModelForItem(itemId)
	if not template then
		return
	end
	local clone = template:Clone()
	clone.Name = "Collectible_" .. itemId
	clone:PivotTo(CFrame.new(position))
	clone.Parent = Workspace
	worldModels[itemId] = clone
	addProximityPrompt(clone, itemId)
end

local function removeLocalModel(itemId: string)
	local model = worldModels[itemId]
	if model and model.Parent then
		model:Destroy()
	end
	worldModels[itemId] = nil
end

local function applyStateFromServer(positions: { [string]: { x: number, y: number, z: number } }, collected: { string })
	collectedItemIds = {}
	for _, id in collected do
		collectedItemIds[id] = true
	end
	itemPositions = {}
	for id, p in positions do
		itemPositions[id] = Vector3.new(p.x, p.y, p.z)
	end
	-- Spawn models only for uncollected items
	for id, pos in itemPositions do
		if not collectedItemIds[id] then
			spawnLocalModel(id, pos)
		else
			removeLocalModel(id)
		end
	end
	-- Remove models for items no longer in positions (e.g. config change)
	for id in worldModels do
		if not itemPositions[id] then
			removeLocalModel(id)
		end
	end
	for _, listener in stateListeners do
		listener(getState())
	end
end

local function onCollectionResult(payload: { success: boolean?, itemId: string?, error: string? })
	if not payload or payload.success ~= true or not payload.itemId then
		return
	end
	local id = payload.itemId
	collectedItemIds[id] = true
	removeLocalModel(id)
	for _, listener in stateListeners do
		listener(getState())
	end
end

-- Connect to server
task.spawn(function()
	local folder = getRemotesFolder()
	if not folder then
		return
	end
	local stateUpdated = folder:WaitForChild(RemoteNames.STATE_UPDATED, 10) :: RemoteEvent?
	local collectionResult = folder:WaitForChild(RemoteNames.COLLECTION_RESULT, 10) :: RemoteEvent?
	if stateUpdated then
		stateUpdated.OnClientEvent:Connect(function(payload)
			if type(payload) == "table" and payload.itemPositions and payload.collectedItemIds then
				applyStateFromServer(payload.itemPositions, payload.collectedItemIds)
			end
		end)
	end
	if collectionResult then
		collectionResult.OnClientEvent:Connect(onCollectionResult)
	end
end)

return CollectiblesController
