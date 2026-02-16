# Collectibles – designer guide

## Overview

The collectible system is **data-driven**. You provide:

- **Biome geometry** (islands/regions) and **spawn areas** (where items may appear)
- **Treasure models** in `ReplicatedStorage.Treasures`
- **Configuration** in `src/shared/Collectibles/Config.luau` (biome IDs, display names, item IDs, model paths, spawn areas)

The game places one instance per collectible type at random positions inside each biome’s spawn areas. Each player can collect each item once; state is saved per player.

## Adding treasure models

- Place one **Model** (or single **BasePart**) per item in **ReplicatedStorage → Treasures**.
- Name each instance to match the **model path** used in config: **`{biomeId}_treasure_{index}`** (e.g. `island_1_treasure_1`, `island_1_treasure_2`).  
  Config uses paths like `"Treasures/island_1_treasure_1"`, so the instance name under `Treasures` must be `island_1_treasure_1`.
- The number of items per biome is set in **Config.luau** in **`ITEM_COUNT_BY_BIOME`** (e.g. `island_1 = 5`). This must match how many models you have for that biome (`island_1_treasure_1` through `island_1_treasure_5`). If a biome is not in the table, the default is 13.
- The system **clones** these at runtime and places them in the world; it does not create or edit the models.

## Display names

By default each item shows as **"Prefix Treasure N"** (e.g. "Island Treasure 1"). To show a specific name (e.g. "Poppy"), add an entry in **Config.luau** in **`DISPLAY_NAME_OVERRIDES`** keyed by item id:

- Item ids are `{biomeId}_treasure_{index}` (e.g. `island_1_treasure_1`, `island_1_treasure_2`).
- Add a line like `island_1_treasure_1 = "Poppy"`. Any item not in the table keeps the default name.

## Biome islands in Workspace

The current biome is **island_1**. Its spawn volume is taken from a **Model in Workspace**:

- Place a **Model** as a direct child of **Workspace** and name it **`island_1`**.
- At runtime the config reads this model’s bounding box (`GetBoundingBox()`) and uses it as the spawn volume: treasures spawn at random positions inside that box.
- If the model is missing or not a Model, the game uses a **fallback** volume (center `45.468, -22.768, -84.443`, default size) so the game still runs.
- Moving or resizing the island in Studio changes spawn positions on the next run.
- **Explicit spawn areas** (see below) override the island bounding box when set.

## Explicit spawn areas

On islands with many structures, spawning inside the whole island bounding box can place treasures inside buildings or in unreachable spots. You can **optionally** define **explicit spawn areas** in **Config.luau** in **`SPAWN_AREAS_BY_BIOME`**. If you set at least one volume (or point) for a biome, only those areas are used—safer and more predictable.

- **How to get numbers:** In Studio, place a **Part** in a safe spot (e.g. flat ground between structures). Note its **Position** (center) and **Size**. In Config, add `volume(px, py, pz, sx, sy, sz)` to that biome’s list in `SPAWN_AREAS_BY_BIOME`. Use 2–5 small volumes for variety.
- **Example (one flat box on the ground):** `volume(50, -23, -80, 20, 2, 20)` — a flat 20×2×20 box keeps treasures at the same height and avoids clipping into structures.
- Leave the list empty `{}` (or omit the biome) to keep automatic behavior (island bounding box or fallback).

## Adding a new biome

1. In **Config.luau**:
   - Add a new entry to `BIOME_IDS`.
   - Add display name in `displayNames` and item prefix in `prefixes` (used for item display names).
   - For workspace-driven spawn (like island_1): ensure a Model with the same name as the biome ID exists under Workspace, or extend `getSpawnAreasByBiomeId()` to support it with a fallback.
2. No changes are required in core services; they read from this config.

## Spawn areas (volume / point)

- **Volume**: `{ type = "volume", position = Vector3.new(x,y,z), size = Vector3.new(w,h,d) }`  
  Items are placed at random inside this box.
- **Point**: `{ type = "point", position = Vector3.new(x,y,z) }`  
  Items are placed exactly at this point (useful for a fixed list of spawn points).

You can add multiple volumes/points per biome; the system picks one at random per item. Use **`SPAWN_AREAS_BY_BIOME`** (see Explicit spawn areas) to define these in config for safe, visible spots.

## UI

The client exposes:

- `CollectiblesController.getState()` – collected item IDs
- `CollectiblesController.getBiomeProgress()` – per-biome counts (collected / total)
- `CollectiblesController.getConfig()` – biomes and items
- `CollectiblesController.subscribeToState(callback)` – real-time updates when the player collects something

Use these to build an index UI grouped by biome and to show collected vs uncollected.
