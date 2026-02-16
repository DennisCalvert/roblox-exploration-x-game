--!strict
--[[
	Server entry: initializes Remotes, persistence, and CollectiblesService.
	Load on player join, save on collection and on leave.
]]

local Players = game:GetService("Players")

local Remotes = require(script.Services.Remotes)
local PlayerDataService = require(script.Services.PlayerDataService)
local CollectiblesService = require(script.Services.CollectiblesService)

-- Ensure remotes exist so client can find them
Remotes.getFolder()

CollectiblesService.start(
	PlayerDataService.getPlayerState,
	PlayerDataService.saveAndUpdate
)

Players.PlayerAdded:Connect(function(player: Player)
	PlayerDataService.onPlayerJoined(player, function(_player, _state)
		CollectiblesService.onPlayerDataLoaded(_player, _state)
	end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	PlayerDataService.onPlayerLeaving(player)
end)

-- Already in-game players (e.g. when script loads after players joined)
for _, player in Players:GetPlayers() do
	PlayerDataService.onPlayerJoined(player, function(_player, _state)
		CollectiblesService.onPlayerDataLoaded(_player, _state)
	end)
end

return nil
