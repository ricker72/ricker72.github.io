# Plan 3 — LegacyX Ingame Successor Simulation

Status: approved for planning; implementation not started

## 1. Objective

Add a deterministic, non-destructive Ingame simulation layer to LegacyX Editor.
NPCs and monsters may walk, turn and animate in the viewport while the underlying
OTBM, spawn XML, creature locations and editor transaction history remain unchanged.

This is an advanced LegacyX feature. It is not presented as RME parity.

## 2. Authority and language boundaries

### RME editing authority

Use only `hampusborgos/rme/master/source` for editor behavior:

- viewport drawing and floor order;
- palettes and editor overlays;
- selection and input;
- creature/spawn editing;
- OTBM and XML persistence.

### Ingame simulation authority

Use the user-supplied 10.91 server source at:

`C:\Users\samatha\OneDrive\Desktop\Editor Alpha\G[10.91] Absolute & Ciroc [FREE VERSION]\src`

Relevant owning files:

- `creature.cpp/.h`: walk scheduler, direction, step duration and ground speed;
- `npc.cpp/.h`: `walkinterval`, `walkradius`, random cardinal movement and tile checks;
- `monster.cpp/.h`: idle movement, `canWalkTo`, master position and despawn zone;
- `spawn.cpp/.h`: center, radius, initial direction and relative positions;
- `map.cpp/.h` and `game.cpp/.h`: tile admission and movement execution.

Production implementation remains C# on .NET 10 Windows Forms. C++ is behavioral
evidence only and must not be copied into the runtime.

## 3. Non-negotiable safety invariants

1. Never change `OtCreature.Location` during preview.
2. Never add, remove or move an `OtCreature` in `OtMap`.
3. Never change `OtSpawn`, its radius, center or creature membership.
4. Never create an `Action`, `BatchAction` or Undo/Redo entry for simulation.
5. Never save simulated positions into OTBM or spawn XML.
6. Never create missing tiles to permit movement.
7. Never infer item IDs or collision flags; use loaded `items.otb` data.
8. Stop simulation before map close, map replacement or resource disposal.
9. The editor must restore the exact static view when simulation is disabled.
10. Simulation must be disabled when DAT/SPR or creature appearances are unavailable.

## 4. Target architecture

Use one read-only simulation service per `MapTabPage`:

```text
MainForm command
    -> MapViewport simulation controls
        -> IngameSimulation (temporary state only)
            -> OtMap/OtTile read-only queries
            -> CreatureAppearanceCatalog read-only lookup
            -> MapRenderer visual snapshots
```

Suggested C# owners:

- `Viewport/IngameSimulation.cs`: clock, lifecycle and state table.
- `Viewport/IngameCreatureState.cs`: origin, visual tile, direction and step timing.
- `Viewport/IngameMovementRules.cs`: read-only movement admission.
- `Viewport/MapViewport.cs`: timer, pause/resume/reset and invalidation.
- `Viewport/MapRenderer.cs`: draw interpolated simulation snapshots.
- `MapTabPage.cs`: per-map lifetime.
- `MainForm.cs`: commands, checked state and status text.
- `Program.cs`: deterministic CLI validator.

Do not add another map model, renderer, timer loop or transaction engine.

## 5. Phased implementation

### Phase 0 — Evidence inventory and baseline

1. Record the exact RME commit SHA.
2. Hash `Dhaoz-1098.otbm`.
3. Record the current Release DLL hash.
4. Run:
   - `--validate-animator`;
   - `--validate-render`;
   - `--validate-creature-render`;
   - `--inspect-map-readonly`.
5. Record existing missing creature XML names separately from renderer failures.

Acceptance:

- baseline results and hashes are stored in the implementation report;
- no source or runtime data has changed.

### Phase 1 — Immutable simulation state

Create `IngameCreatureState` with:

- creature ID/reference;
- immutable origin position;
- immutable spawn center and radius;
- current visual position;
- previous visual position;
- visual direction;
- step start and duration;
- walking/idle state;
- NPC/monster classification.

State must be created from map data but must never be written back.

Acceptance:

- starting and stopping simulation leaves every `OtCreature` property identical;
- map and spawn fingerprints remain identical.

### Phase 2 — Lifecycle controller

Implement one `IngameSimulation` per map:

- `Start`;
- `Pause`;
- `Resume`;
- `Reset`;
- `Stop`;
- `Advance(elapsedMilliseconds)`;
- immutable render snapshot retrieval.

Use the existing viewport animation timer as the only UI heartbeat. The simulation
controller receives elapsed time; it must not create a second WinForms timer.

Acceptance:

- repeated start/stop does not leak state or event handlers;
- inactive or hidden viewports consume no simulation work;
- closing a tab disposes its simulation.

### Phase 3 — NPC configuration importer

Extend `CreatureAppearanceCatalog` with optional simulation metadata parsed from
the same NPC XML:

- `speed`, defaulting exactly as `npc.cpp`;
- `walkinterval`, defaulting exactly as `npc.cpp`;
- `walkradius`;
- `floorchange`;
- `ignoreheight`.

Do not change the outfit parser. Missing attributes use source-proven defaults.
Malformed values produce a diagnostic and disable movement for that NPC.

Acceptance:

- representative XML files produce the same values as the 10.91 loader;
- `walkinterval <= 0` produces a stationary NPC;
- `walkradius == 0` produces a stationary NPC.

### Phase 4 — Spawn ownership

Resolve each map creature to its existing `OtSpawn` without modifying membership.
Use the real spawn center, radius and original relative position.

Rules:

- movement remains on the creature's original floor;
- position must remain inside the square spawn zone used by the source;
- creatures with unresolved spawn ownership remain stationary;
- radius `-1` and other special values are handled only after confirming source behavior.

Acceptance:

- every moving state has a certified spawn owner;
- no preview state leaves its permitted zone.

### Phase 5 — Read-only collision rules

Implement cardinal admission using existing `OtMap` and `OtTile`:

- target tile must already exist;
- target must have ground;
- reject `OtTile.IsBlocking`;
- reject blocking ground/items based on loaded OTB flags;
- reject occupied visual destination;
- respect NPC floor-change, teleport and height rules only when the local model can
  prove those flags from official data.

If a server rule cannot be represented by current metadata, mark it unsupported and
keep the creature stationary. Do not guess.

Acceptance:

- fixtures cover free, absent, blocking and occupied destinations;
- collision evaluation performs no map mutations.

### Phase 6 — Deterministic cardinal selection

Port the NPC candidate order from `npc.cpp`:

- North;
- South;
- East;
- West.

Choose uniformly from valid candidates. Inject clock and random providers so CLI
tests are deterministic. Production may use a per-map random generator.

Acceptance:

- invalid candidates are never selected;
- fixed random seeds reproduce the same preview;
- direction changes before the visual step begins.

### Phase 7 — Step timing and interpolation

Translate source-proven step duration:

- base creature speed;
- target ground speed from `OtTile.GetGroundSpeed()`;
- cardinal step cost;
- source rounding interval.

Represent motion as a visual interpolation from previous to current visual tile.
Do not render a creature twice during a step.

Acceptance:

- interpolation starts at 0 and ends at exactly one tile;
- no drift accumulates after many steps;
- pausing freezes the interpolation;
- low frame rate preserves elapsed-time overshoot.

### Phase 8 — Walk animation coupling

Connect movement state to the existing `SpriteAnimator`:

- idle uses the appropriate stationary phase policy;
- walking advances the creature frame group;
- direction selects DAT pattern X;
- mount, addons, template colors and body `pattern_z` remain intact;
- stop walking returns cleanly to idle without resetting unrelated item animations.

Acceptance:

- four directions work for mounted and unmounted outfits;
- multi-sprite creatures are not flattened;
- Animator finite, random and ping-pong tests continue passing.

### Phase 9 — Monster idle movement

Port only source-proven idle wandering first. Combat, fleeing, targeting, spells,
summons and Lua AI are outside the editor preview scope.

Rules:

- remain inside spawn/master zone;
- use the same collision service;
- do not chase editor cursors or users;
- respect source-proven idle timing;
- unresolved monster metadata means stationary rendering.

Acceptance:

- monsters wander without leaving their spawn;
- no combat state is invented;
- NPC and monster scheduling remain independent.

### Phase 10 — Ingame UI controls

Add controls without overloading the existing generic `ShowPreview` option:

- Start Ingame Simulation;
- Pause/Resume;
- Reset Positions;
- Stop;
- simulation speed: 0.25x, 0.5x, 1x, 2x;
- optional collision/spawn diagnostic overlay.

Place commands in the existing View/Ingame area and expose compact toolbar controls.
Persist only user preferences such as speed and overlay visibility, never runtime
positions.

Acceptance:

- checked/enabled states follow the active map;
- shortcuts do not fire while typing in Planner prompts;
- stopping returns instantly to the static editor view.

### Phase 11 — Diagnostics console

Record structured, non-sensitive events:

- simulation start/stop/pause/reset;
- active state count;
- rejected step reason categories;
- average update duration;
- dropped/overshoot steps;
- unresolved appearance/configuration.

Never log full map contents, prompts, credentials or every creature position.

Acceptance:

- diagnostics can identify scheduler, collision, renderer or XML ownership;
- large maps do not flood the console.

### Phase 12 — Performance and viewport culling

Update only:

- creatures on the active floor;
- creatures within the viewport plus a small margin;
- states whose next scheduled update is due.

Use immutable frame snapshots so renderer enumeration cannot race simulation updates.
Set a measurable frame-time budget before optimization.

Acceptance:

- `Dhaoz-1098.otbm` remains responsive at 1x simulation;
- hidden tabs perform no animation work;
- memory returns to baseline after map close.

### Phase 13 — Persistence firewall

Add explicit automated checks around:

- Save;
- Save As;
- map roundtrip;
- copy/paste;
- import map;
- Undo/Redo;
- tab close.

Acceptance:

- OTBM and spawn XML hashes are identical whether simulation ran or not;
- no simulation state appears in serialized output;
- editor transactions remain unchanged.

### Phase 14 — Certification

Add `--validate-ingame-simulation` using a small in-memory map built from loaded,
official item metadata. Validate:

- stationary NPC conditions;
- radius boundaries;
- blocking and missing tiles;
- deterministic direction selection;
- occupied destinations;
- timing and interpolation;
- pause/resume/reset/stop;
- mounted/addon/directional rendering;
- immutable map and creature fingerprints.

Then run Release-only certification:

```powershell
dotnet build SharpMapTracker\SharpMapTracker.csproj -c Release --no-restore
dotnet SharpMapTracker\bin\Release\net10.0-windows\LegacyXEditor.dll --validate-ingame-simulation "<Tibia>"
dotnet SharpMapTracker\bin\Release\net10.0-windows\LegacyXEditor.dll --validate-animator
dotnet SharpMapTracker\bin\Release\net10.0-windows\LegacyXEditor.dll --validate-render "<Tibia>"
dotnet SharpMapTracker\bin\Release\net10.0-windows\LegacyXEditor.dll --validate-creature-render "<Tibia>" "<server-data>" "<map>"
dotnet SharpMapTracker\bin\Release\net10.0-windows\LegacyXEditor.dll --inspect-map-readonly "<Tibia>" "<map>"
```

Do not call the feature complete until all simulation checks pass and any missing
XML names are reported separately from rendering/simulation defects.

## 6. Deferred systems

The following require their own evidence and plans:

- combat, targeting and fleeing;
- spells, projectiles and damage;
- Lua NPC scripts and dialogue;
- player simulation;
- floor-changing movement and teleports;
- creature respawn/despawn lifecycle;
- network protocol emulation.

They must not be silently included in the first movement implementation.

## 7. Recommended execution order

Implement in these reviewable blocks:

1. Phases 0–2: immutable state and lifecycle.
2. Phases 3–6: metadata, spawn and collision.
3. Phases 7–9: interpolation, animation and monsters.
4. Phases 10–12: UI, diagnostics and performance.
5. Phases 13–14: persistence firewall and certification.

Each block must compile in Release and pass its focused validator before the next
block begins.
