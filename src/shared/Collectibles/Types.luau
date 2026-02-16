--!strict
--[[
	Shared type definitions for the biome-based collectible system.
	Used by config, server, and client.
]]

export type SpawnPoint = {
	type: "point",
	position: Vector3,
}

export type SpawnVolume = {
	type: "volume",
	position: Vector3,
	size: Vector3,
}

export type SpawnArea = SpawnPoint | SpawnVolume

export type BiomeConfig = {
	id: string,
	displayName: string,
	itemIds: { string },
	spawnAreas: { SpawnArea },
}

export type ItemConfig = {
	id: string,
	displayName: string,
	biomeId: string,
	modelPath: string, -- path in ReplicatedStorage, e.g. "Treasures/GoldCoin"
	description: string?, -- optional; shown in Index detail view for collected items
}

export type CollectiblesConfig = {
	biomes: { BiomeConfig },
	items: { ItemConfig },
}

export type PlayerCollectionState = {
	collectedItemIds: { string },
}

-- Per-biome progress for UI (derived from collectedItemIds + config)
export type BiomeProgress = {
	biomeId: string,
	collectedCount: number,
	totalCount: number,
	collectedItemIds: { string },
}

return nil
