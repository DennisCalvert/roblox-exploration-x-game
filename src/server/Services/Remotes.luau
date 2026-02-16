--!strict
--[[
	Creates and exposes remote events for collectibles.
	Server creates these and parents to ReplicatedStorage so client can access.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.Shared.Collectibles.RemoteNames)

local folder: Folder
local requestCollect: RemoteEvent?
local collectionResult: RemoteEvent?
local stateUpdated: RemoteEvent?

local function ensureFolder(): Folder
	if folder then
		return folder
	end
	local existing = ReplicatedStorage:FindFirstChild("CollectiblesRemotes")
	if existing and existing:IsA("Folder") then
		folder = existing :: Folder
		requestCollect = folder:FindFirstChild(RemoteNames.REQUEST_COLLECT) :: RemoteEvent?
		collectionResult = folder:FindFirstChild(RemoteNames.COLLECTION_RESULT) :: RemoteEvent?
		stateUpdated = folder:FindFirstChild(RemoteNames.STATE_UPDATED) :: RemoteEvent?
		if not requestCollect then
			local req = Instance.new("RemoteEvent")
			req.Name = RemoteNames.REQUEST_COLLECT
			req.Parent = folder
			requestCollect = req
		end
		if not collectionResult then
			local res = Instance.new("RemoteEvent")
			res.Name = RemoteNames.COLLECTION_RESULT
			res.Parent = folder
			collectionResult = res
		end
		if not stateUpdated then
			local ev = Instance.new("RemoteEvent")
			ev.Name = RemoteNames.STATE_UPDATED
			ev.Parent = folder
			stateUpdated = ev
		end
		return folder
	end
	folder = Instance.new("Folder")
	folder.Name = "CollectiblesRemotes"
	folder.Parent = ReplicatedStorage
	requestCollect = Instance.new("RemoteEvent")
	requestCollect.Name = RemoteNames.REQUEST_COLLECT
	requestCollect.Parent = folder
	collectionResult = Instance.new("RemoteEvent")
	collectionResult.Name = RemoteNames.COLLECTION_RESULT
	collectionResult.Parent = folder
	stateUpdated = Instance.new("RemoteEvent")
	stateUpdated.Name = RemoteNames.STATE_UPDATED
	stateUpdated.Parent = folder
	return folder
end

ensureFolder()

return {
	getFolder = ensureFolder,
	getRequestCollect = function(): RemoteEvent
		ensureFolder()
		return requestCollect :: RemoteEvent
	end,
	getCollectionResult = function(): RemoteEvent
		ensureFolder()
		return collectionResult :: RemoteEvent
	end,
	getStateUpdated = function(): RemoteEvent
		ensureFolder()
		return stateUpdated :: RemoteEvent
	end,
}
