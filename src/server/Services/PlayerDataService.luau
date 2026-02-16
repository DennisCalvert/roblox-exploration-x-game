--!strict
--[[
	Persists player collection state (collected item IDs).
	Load on join, save on collection, save on leave. Survives server restart.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Types = require(game:GetService("ReplicatedStorage").Shared.Collectibles.Types)
type PlayerCollectionState = Types.PlayerCollectionState

local DATASTORE_KEY = "Collectibles_v1"
local ds = DataStoreService:GetDataStore(DATASTORE_KEY)

-- In-memory cache: userId -> state
local playerStates: { [number]: PlayerCollectionState } = {}

local function getKey(player: Player): string
	return "plr_" .. player.UserId
end

local function loadState(player: Player): PlayerCollectionState?
	local key = getKey(player)
	local ok, result = pcall(function()
		return ds:GetAsync(key)
	end)
	if not ok or result == nil then
		return { collectedItemIds = {} }
	end
	if type(result) == "table" and type(result.collectedItemIds) == "table" then
		return {
			collectedItemIds = result.collectedItemIds :: { string },
		}
	end
	return { collectedItemIds = {} }
end

local function saveState(player: Player, state: PlayerCollectionState): boolean
	local key = getKey(player)
	local ok = pcall(function()
		ds:SetAsync(key, {
			collectedItemIds = state.collectedItemIds,
		})
	end)
	return ok
end

local PlayerDataService = {}

function PlayerDataService.getPlayerState(player: Player): PlayerCollectionState?
	return playerStates[player.UserId]
end

function PlayerDataService.saveAndUpdate(player: Player, state: PlayerCollectionState): ()
	playerStates[player.UserId] = state
	saveState(player, state)
end

function PlayerDataService.onPlayerJoined(player: Player, onLoaded: (Player, PlayerCollectionState) -> ())
	local state = loadState(player) or { collectedItemIds = {} }
	playerStates[player.UserId] = state
	onLoaded(player, state)
end

function PlayerDataService.onPlayerLeaving(player: Player)
	-- Ensure latest state is saved (in case of mid-collection)
	local state = playerStates[player.UserId]
	if state then
		saveState(player, state)
	end
	playerStates[player.UserId] = nil
end

return PlayerDataService
