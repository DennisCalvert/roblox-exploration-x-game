--!strict
--[[
	Remote event/function names for collectibles.
	Server creates these under ReplicatedStorage; client references by name.
]]

return {
	REQUEST_COLLECT = "CollectiblesRequestCollect",
	COLLECTION_RESULT = "CollectiblesCollectionResult",
	STATE_UPDATED = "CollectiblesStateUpdated",
}
