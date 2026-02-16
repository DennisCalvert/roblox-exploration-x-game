# Collectibles configuration – design team guide

This README explains how to configure collectible items (treasures) and related biomes so the design team can add, rename, and wire up new content without changing game code.

---

## Where configuration lives

| What you configure | Where it lives |
|-------------------|----------------|
| **Item definitions** (ID, name, biome, model) | `src/shared/Collectibles/Config.luau` |
| **Treasure models** (the 3D assets) | **ReplicatedStorage → Treasures** in Roblox Studio |

The game reads from `Config.luau` and clones models from `ReplicatedStorage.Treasures` at runtime. It does **not** create or edit models—only places clones in the world.

---

## How an item is defined

Each collectible has:

| Field | Purpose |
|-------|--------|
| **id** | Unique string used in code and save data (e.g. `coral_reef_treasure_1`). Don’t change after release or players may lose progress. |
| **displayName** | Name shown in UI (e.g. "Coral Treasure 1"). |
| **biomeId** | Which biome the item belongs to (must match a biome in config). |
| **modelPath** | Path under ReplicatedStorage to the model (e.g. `Treasures/coral_reef_1`). |

**Example (from Config.luau):**

```lua
{
	id = "coral_reef_treasure_1",
	displayName = "Coral Treasure 1",
	biomeId = "coral_reef",
	modelPath = "Treasures/coral_reef_1",
}
```

- **modelPath** = `"Treasures/coral_reef_1"` means the game looks for **ReplicatedStorage.Treasures.coral_reef_1**.
- The instance under `Treasures` can be a **Model** or a single **BasePart**; name it exactly as in the path (`coral_reef_1`).

---

## Configuring items in Config.luau

### Current setup

Items are generated in **Config.luau** by:

1. **BIOME_IDS** – list of biome IDs (e.g. `coral_reef`, `volcanic`).
2. **itemsForBiome(biomeId, displayPrefix)** – builds a set of items per biome (e.g. 13 per biome), with:
   - `id` = `biomeId .. "_treasure_" .. index`
   - `displayName` = `displayPrefix .. " Treasure " .. index`
   - `modelPath` = `"Treasures/" .. biomeId .. "_" .. index`
3. **prefixes** – short label per biome used in display names (e.g. "Coral", "Volcanic").

So for **coral_reef** you get items like:

- `coral_reef_treasure_1` → display "Coral Treasure 1" → model `Treasures/coral_reef_1`
- `coral_reef_treasure_2` → "Coral Treasure 2" → `Treasures/coral_reef_2`
- …up to 13.

### To add more items per biome

In **Config.luau**, change the loop in **itemsForBiome** (e.g. `for i = 1, 13` → `for i = 1, 20`). Keep naming consistent:

- **id**: `biomeId .. "_treasure_" .. i`
- **modelPath**: `"Treasures/" .. biomeId .. "_" .. i`

Then add matching models in **ReplicatedStorage.Treasures** (e.g. `coral_reef_14` … `coral_reef_20`).

### To add fully custom items

You can append extra entries to the **items** list returned by **allItems()** (or add a separate table that gets merged). Each entry must have:

- **id** (unique)
- **displayName**
- **biomeId** (must exist in **BIOME_IDS** and in **biomes**)
- **modelPath** (e.g. `"Treasures/MyCustomTreasure"`)

Ensure the biome’s **itemIds** in the config includes this new **id**, or the item won’t be part of that biome’s set and won’t spawn in that biome’s areas.

### To change display names only

- **prefixes** in Config controls the first word (e.g. "Coral", "Volcanic").
- Or edit **itemsForBiome** to use custom names instead of `displayPrefix .. " Treasure " .. index`.

### To change where items spawn

Items spawn at **random positions inside each biome’s spawn areas**. Spawn areas are defined in **spawnAreasForBiome(index)** (and related helpers) in Config:

- **Volume**: a box; items are placed at random inside it.
- **Point**: a single position; the item is placed exactly there.

Adding or editing volumes/points in config is enough; no code changes elsewhere are required.

---

## Adding treasure models (Studio)

1. In **Explorer**, go to **ReplicatedStorage**.
2. Ensure there is a **Treasures** folder (it’s in the project; if missing, create a Folder named `Treasures`).
3. For each item, add a **Model** (or a single **Part**) as a child of **Treasures**.
4. **Name** the instance to match **modelPath** in config:
   - Config path `Treasures/coral_reef_1` → instance name **coral_reef_1**.
   - Config path `Treasures/volcanic_2` → instance name **volcanic_2**.

If a model is missing, that item simply won’t appear in the world for players; the game won’t error.

---

## Adding a new biome

1. In **Config.luau**:
   - Add the new ID to **BIOME_IDS**.
   - In **displayNames**, add a display name (e.g. `new_biome = "New Island"`).
   - In **prefixes**, add a prefix for item names (e.g. `new_biome = "New"`).
   - In **spawnAreasForBiome**, add spawn volumes or points for the new biome index (or extend the helper so the new biome gets its areas).
2. Items for the new biome are created by **itemsForBiome** and **allItems()** once the new biome ID is in **BIOME_IDS** and **prefixes**.
3. Add the corresponding models under **ReplicatedStorage.Treasures** (same naming: `new_biome_1`, `new_biome_2`, …).

No changes are required in server or client logic; they read from this config.

---

## Naming checklist

- **Item id**: unique, stable (avoid changing after release). Example: `coral_reef_treasure_1`.
- **modelPath**: must match hierarchy under ReplicatedStorage. Example: `Treasures/coral_reef_1` → instance **Treasures** → **coral_reef_1**.
- **biomeId**: must match an entry in **BIOME_IDS** and in the biomes list built in Config.

---

## Quick reference

| Task | File / place | What to do |
|------|------------------|------------|
| Change how many items per biome | Config.luau | Change the loop in **itemsForBiome** (e.g. 1..13 → 1..20). |
| Change item display names | Config.luau | Edit **prefixes** or **itemsForBiome** display name logic. |
| Change where items spawn | Config.luau | Edit **spawnAreasForBiome** (volumes/points). |
| Add a new biome | Config.luau | Add to **BIOME_IDS**, **displayNames**, **prefixes**, and spawn areas. |
| Add or replace 3D treasure | ReplicatedStorage.Treasures | Add/rename Model or Part to match **modelPath** (e.g. `coral_reef_1`). |

For more detail on spawn area types and UI data (e.g. for an index screen), see **COLLECTIBLES_DESIGNER.md** in this folder.
