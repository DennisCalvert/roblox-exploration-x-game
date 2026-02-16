# Phase 3: Index UI – Rojo-Synced Hierarchy (Follow-Up)

## Scope

Migrate the Phase 2 Index UI from **code-created** instances (Option A) to a **Rojo-synced** instance tree (Option B) so that:

- The Index layout and hierarchy live in the repo as instance definitions (e.g. `.model.json` or Rojo project files).
- Designers can change layout, hierarchy, and default properties without editing Luau.
- `default.project.json` includes a `StarterGui` entry with a `$path` to the Index UI folder; Rojo sync creates/updates the UI tree when the project is synced.

## Out of scope

- No new Index features or behavior; only the source of the UI tree changes (code → synced files).
- No changes to collection logic or Phase 1 systems.

## Prerequisites

- Phase 2 Index UI is implemented and working (Option A: UI created in client scripts).

## Success criteria

- Index ScreenGui (and its structure) is defined under a path synced via Rojo (e.g. `src/gui/Index`).
- `default.project.json` includes `StarterGui` with a `$path` to that folder.
- Client scripts clone or reference the synced UI from StarterGui/PlayerGui and wire behavior (state, navigation, ViewportFrames) as in Phase 2.
- Layout/structure changes in the synced files appear in-game after sync without script changes.
