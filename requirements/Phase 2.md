# 🌊 Cursor Implementation Prompt

## Feature: Polished Collection Index (Phase 2)

You are implementing **Phase 2** of the Biome-Based Collectible System.

Phase 1 (collection, persistence, validation, spawning) is complete and working.

This phase focuses exclusively on a **polished, player-facing Index UI experience** that displays discovered items.

**Do not modify collection logic.**  
**Do not redesign backend architecture.**  
Focus only on product-level and UX requirements.

---

# 1. Feature Overview

The Index is a **fully designed, navigable collection journal** that allows players to:

- View all biomes
- Inspect items within each biome
- See collected vs uncollected status
- View detailed item information
- Track completion progress
- Experience satisfying visual feedback

This system must feel:

- Clean
- Responsive
- Organized
- Scalable to 100+ items
- Console and mobile friendly

---

# 2. High-Level UX Goals

The Index should:

- Encourage exploration
- Reinforce progression
- Showcase collectible art/models
- Make completion clear and motivating
- Avoid clutter or overwhelming the player

The experience should feel closer to a **collection journal**, not a debug list.

---

# 3. Navigation Structure

## 3.1 Entry Point

The Index must be accessible through:

- A persistent UI button (HUD element)
- Console-compatible navigation
- Mobile-friendly tap interaction

Opening the Index:

- Does not interrupt the game world
- May blur or dim background
- Must be closable easily
- Must not trap input focus

---

## 3.2 Layout Structure

The Index must contain:

### Level 1: Biome Overview Screen

Displays:

- All biomes
- Biome name
- Biome icon or representative image
- Completion percentage
- Collected count (e.g., `7 / 12`)

Biomes must be:

- Visually distinct
- Clearly selectable
- Ordered consistently (config-driven order)

Locked biome visuals may be supported but are not required.

---

### Level 2: Biome Detail Screen

When selecting a biome, show:

- Biome name (prominent header)
- Completion bar
- Total collected / total items
- Grid of items

Items must be displayed in a **consistent grid layout**.

---

# 4. Item Display Requirements

Each item in the grid must visually represent its state.

## 4.1 Collected Items

Must show:

- Full color icon or model preview
- Display name visible
- Optional short description (if available)
- Subtle visual confirmation (checkmark, glow, or highlight)

Must feel rewarding.

---

## 4.2 Uncollected Items

Must show:

- Silhouette, blurred, or darkened state
- Name hidden or replaced with `"???"`
- No detailed description
- No hidden metadata exposed

Uncollected items should create curiosity without spoilers.

---

# 5. Item Detail View (Drill-Down)

Selecting a collected item opens a detail panel.

Must include:

- Large preview (image or 3D viewport model)
- Display name
- Biome name
- Description text (config-driven)
- Collection confirmation indicator

Uncollected items:

- Show silhouette only
- Hide name and description
- Reveal no hidden data

Detail panel must:

- Animate in/out
- Be dismissible easily
- Not block navigation unexpectedly

---

# 6. Progress Tracking

## 6.1 Per Biome

Display:

- Numeric progress (`X / Total`)
- Visual progress bar
- Percentage

Progress must update in real time when an item is collected.

---

## 6.2 Global Progress

Display:

- Total collected across all biomes
- Overall completion percentage

Must update live and remain consistent across sessions.

---

# 7. Real-Time Update Behavior

When a player collects an item:

- Index UI updates immediately (if open)
- Biome completion recalculates instantly
- Progress bars animate smoothly
- Newly collected item transitions visually from hidden → revealed

If the Index is closed, data must still update in background.

---

# 8. Sorting & Organization Requirements

Within a biome:

- Items must display in consistent order
- Order must be config-driven (not random)
- Grid must scale gracefully for 5–50 items per biome

System must support:

- 8+ biomes
- 100+ total items

Opening large biomes must not cause noticeable delay.

---

# 9. State Persistence & UX Continuity

The Index must:

- Reflect persisted data on join
- Not flicker or misreport counts on load
- Gracefully handle slow data loading
- Display a loading state if necessary
- Avoid showing incorrect 0/Total during data fetch

Optional enhancement:

- Maintain last viewed biome during the session

---

# 10. Visual & Interaction Requirements

The Index must:

- Animate open/close
- Support hover (PC), selection (console), and tap (mobile)
- Be readable on small screens
- Avoid tiny click targets
- Avoid excessive nested scrolling
- Maintain strong contrast for readability

UI must:

- Match game theme
- Use consistent typography
- Be visually clean and structured

---

# 11. Performance Requirements

The Index must:

- Not request excessive server calls
- Not poll continuously
- Use event-driven updates
- Avoid per-frame UI recalculations
- Work in `StreamingEnabled` environments

Opening the Index must not cause frame drops.

---

# 12. Edge Cases

Handle:

- Player collecting item while Index is open
- Player opening Index before data finishes loading
- Biome with zero collected items
- Biome fully completed
- New biome added in configuration
- New item added to existing biome
- Player reconnect after partial session

UI must not break when content expands.

---

# 13. Explicit Non-Goals (Do Not Implement)

Do NOT implement:

- Completion rewards
- Claim buttons
- Rarity tiers
- Animated unlock cinematics
- Leaderboards
- Trading
- Item filtering
- Search bar
- Sorting controls
- Badges
- Achievements

This phase is strictly a **polished visual Index layer** over existing data.

---

# 14. Success Criteria

Phase 2 is complete when:

- Players can open a clean Index UI
- Biomes display accurate completion percentages
- Items clearly show collected vs uncollected state
- Item details can be viewed (if collected)
- UI updates in real time upon collection
- 100+ items perform smoothly
- Adding new biomes or items via configuration automatically appears in the Index
- No backend collection changes were required

---

# Implementation Instructions

Use the existing data exposed from Phase 1.

Do not refactor core collection logic.

Generate:

- Screen definitions
- UI state definitions
- Interaction flow
- Progress calculation rules
- Visual state rules (collected vs uncollected)
- Update behavior definitions
- Edge case handling requirements

Do not introduce speculative systems beyond the Index.
