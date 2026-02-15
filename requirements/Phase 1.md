# 🌊 Cursor Implementation Prompt

## Feature: Biome-Based Collectible System (V1)

You are implementing a **scalable, server-authoritative collectible system** for a Roblox game.

Follow the requirements strictly.  
**Do not implement Phase 2 or speculative features.**

---

## 1. Feature Overview

Players explore an ocean world containing multiple islands.  
Each island represents a distinct biome.

Each biome contains unique collectible treasure items.

Players can:

- Discover treasures in the world
- Collect them
- Track their collection progress
- Persist progress across sessions

This system must be **modular and extensible**.

---

## 2. Core Gameplay Requirements

### 2.1 Biomes

Each island is a biome.

Each biome must have:

- Unique string identifier
- Display name
- Defined set of collectible item IDs

Biomes must be **data-driven** (not hardcoded logic branches).

Adding a new biome must **not require refactoring core systems**.

---

### 2.2 Items (Treasures)

Each collectible item must have:

- Unique ID (globally unique string)
- Display name
- Associated biome
- World model representation
- Collectible state per player

The world model representation for each item must be **configurable** (e.g. a reference to a designer-built model or to a specific instance in the world). The system must not generate or hardcode the model.

#### Constraints:

- An item belongs to exactly one biome.
- Items are placed physically in the world.
- Items are interactable through proximity.

---

### 2.3 Collection Rules

Collection is **server-authoritative**.

A player may collect each item **only once**.

Upon valid collection:

- Item disappears (at minimum for that player)
- Player data updates immediately
- Client UI updates in real time

Duplicate collection attempts must fail safely.

---

## 3. Multiplayer Behavior

- Collection is **per-player**, not global.
- One player collecting an item does **NOT** remove it for others.
- Each player maintains independent collection state.

---

## 4. Persistence Requirements

For each player, persist:

- List of collected item IDs
- Collection progress per biome

#### Requirements:

- Load on player join
- Save on collection
- Save on player leave
- Survive server restart

---

## 5. World Placement Requirements

Each biome contains defined spawn locations for items.

Items must spawn into their corresponding biome only.

System must support at least:

- 8+ biomes
- 100+ total collectible items

Spawning must **not rely on hardcoded biome checks**.

---

## 6. Configuration and Designer-Built Assets

Biome and item definitions must be **configurable** so that designer-built islands and treasures can be wired in without code changes.

- **Configuration source**: Biome and item definitions (IDs, display names, which items belong to which biome, world model references, spawn or placement info) must come from a **configuration layer** (e.g. ModuleScripts, JSON, or Roblox instance attributes/folders) that can be updated without changing core game logic.
- **Designer-owned assets**: Islands and treasure models are built by designers and placed in the world or in storage (e.g. ReplicatedStorage). The implementation must **consume** these assets via configuration (e.g. mapping biome ID → island instance or folder; item ID → model reference or in-world instance), not create or duplicate them.
- **Binding**: The system must support a defined way to associate config (biome ID, item ID) with the actual instances (which island, which collectible model/placement). Examples: attributes on instances, naming conventions, or a config table that references instance paths/names. The exact mechanism can be chosen in implementation, but the requirement is that binding is driven by config/data, not hardcoded in logic.

---

## 7. Validation & Security Requirements

The server must validate:

- The item exists
- The item belongs to a valid biome
- The player is within a reasonable distance
- The item has not already been collected by the player

The client must **NOT**:

- Define arbitrary item IDs
- Modify collection state
- Bypass validation

All collection logic must execute on the **server**.

---

## 8. UI Support Requirements

The system must expose sufficient data to allow:

- An index-style UI
- Grouping by biome
- Displaying collected vs uncollected items
- Real-time UI updates on collection
- Persisted UI state across sessions

UI implementation may be minimal for V1, but backend support must exist.

---

## 9. Performance Requirements

- No excessive remote event spam
- No expensive loops per frame
- Must support `StreamingEnabled` environments
- Must not cause server lag when multiple players join simultaneously

---

## 10. Edge Cases

Handle:

- Duplicate collection attempts
- Player disconnect mid-collection
- Exploit remote spam
- Items spawning after player joins
- Late-loading island assets

---

## 11. Explicit Non-Goals (Do Not Implement)

Do **NOT** implement:

- Rarity tiers
- Respawn timers
- Randomized loot tables
- Trading
- Biome completion rewards
- Achievements
- Leaderboards
- Procedural spawn logic

---

## 12. Success Criteria

The feature is complete when:

- Multiple islands exist
- Each island contains unique collectibles
- Players can collect items once
- Collection persists across sessions
- UI can accurately reflect biome progress
- New biomes can be added without modifying core logic

---

## Implementation Instructions

Design this system using:

- Clear separation of responsibilities
- Server-authoritative logic
- Data-driven biome and item definitions
- Modular services and controllers
- Secure remote communication
- Clean and scalable structure

Generate:

- Data models
- Services
- Remote definitions
- Client update handling
- Validation logic
- Persistence integration
- Configuration format and binding strategy for biomes and items (so designer-built islands and treasures can be wired in without code changes)

Do not include Phase 2 features.
