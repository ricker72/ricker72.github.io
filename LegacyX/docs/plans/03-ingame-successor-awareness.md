# Plan 3b — LegacyX Ingame Awareness (monster aggro + voices)

Status: implemented; awaiting Release certification

## 1. Objective

Extend the Plan 3 Ingame successor simulation so monsters can sense and chase the
GOD player and emit idle voice bubbles, all inside the same read-only, deterministic
simulation layer. Combat, damage, fleeing, summons, spells, Lua NPC dialogue and full
player simulation remain explicitly out of scope (Plan 3 §6).

This is an advanced LegacyX feature and is not presented as RME parity.

## 2. Authority and evidence

Editor rendering authority: `hampusborgos/rme/master/source` at commit
`da7152ec94031c76732e997de4624c8f1c010225`. RME `master` does not define an ingame
awareness/aggro model; no live_sim file exists there.

Ingame awareness authority: the user-supplied 10.91 server source at
`C:\Users\samatha\OneDrive\Desktop\Editor Alpha\G[10.91] Absolute & Ciroc [FREE VERSION]\src`.
No other RME fork, Canary, TFS, OTClient or wiki was used as compatibility evidence.

### Evidence chain

| Behavior | 10.91 source | LegacyX owner |
|---|---|---|
| Vision window ±11 | `creature.cpp:96-120` `Creature::canSee`, `map.h:177-178` `maxViewportX/Y = 11` | `IngameSimulation.UpdateAggro` |
| Same-floor requirement | `monster.cpp:620-631` `Monster::isTarget` | `IngameSimulation.UpdateAggro` |
| Sight-line gate | `monster.cpp:1267` `isSightClear(...,true)`, `map.cpp:545-553` `Map::isSightClear`, `map.cpp:497-543` `checkSightLine` | `IngameMovementRules.IsSightClear/CheckSightLine` |
| BLOCKPROJECTILE blocker | `map.cpp:527` `CONST_PROP_BLOCKPROJECTILE` | `IngameMovementRules.HasBlockProjectile` |
| Chase admission (no spawn leash) | `monster.cpp:1267-1271` `getDistanceStep`, `map.cpp:555-572` `canWalkTo`/`queryAdd` | `IngameMovementRules.CanMonsterChaseMoveTo` |
| Chase stop at targetDistance | `monster.cpp:1269-1270` `distance == targetDistance` | `IngameSimulation.SelectChaseDirection` |
| targetDistance default | `monsters.cpp:62` `targetDistance = 1` | `IngameCreatureConfig.TargetDistance` |
| targetDistance XML | `monsters.cpp:833` `<targetdistance>` | `CreatureAppearanceCatalog.ParseSimulationConfig` |
| Voices XML | `monsters.cpp:1054-1081` `<voices speed|interval chance>` `<voice sentence yell>` | `CreatureAppearanceCatalog.ParseVoices` |
| Voices disabled by default | `monsters.cpp:95-97` `yellSpeedTicks/yellChance = 0` | `IngameCreatureConfig.Voices` (null) |
| Voice timing + roll | `monster.cpp:976-997` `Monster::onThinkYell` | `IngameSimulation.UpdateVoices` |
| SAY vs YELL | `monster.cpp:990-994` `TALKTYPE_MONSTER_YELL/SAY` | `IngameCreatureState.Speak` (SpeechIsYell) |

### Explicit non-goals (remain deferred, Plan 3 §6)

- combat damage and health;
- fleeing / runAwayHealth;
- spells, projectiles, summons;
- Lua NPC scripts and dialogue (NPC greeting is Lua-only in 10.91:
  `npc.cpp:253-270` `Npc::onCreatureAppear` delegates to `m_npcEventHandler`);
- full player simulation beyond the GOD walker;
- creature respawn/despawn;
- network protocol emulation.

No NPC aggro/greeting is implemented because the 10.91 C++ server gives NPCs no
aggro or greeting state; `Npc::canSee` (`npc.cpp:236-242`) is used only to decide
which creatures the NPC sees for its Lua callback, never for combat targeting.

## 3. Design decisions

1. **Aggro is movement-only.** A monster that acquires the GOD player chases it via a
   bounded BFS that reuses `CanMonsterChaseMoveTo` (no spawn-zone restriction, matching
   the server's non-blocking leash). No damage is applied.
2. **Target lifetime.** A monster acquires the player when same-floor, within ±11, and
   `IsSightClear`. It keeps the target while still same-floor and in range, even when
   the direct line is momentarily blocked (the BFS routes around), matching the server's
   A* behaviour in `monster.cpp:1267`. It loses the target when the player leaves range,
   changes floor, or god mode turns off.
3. **Voice bubbles are simulation-clock based**, so CLI validators stay deterministic.
   The speech bubble on-screen duration (`SpeechBubbleMs = 4000`) is an editor-visual
   constant, not a server value (the client owns bubble lifetime).
4. **Renderer-agnostic bubbles.** Speech bubbles are drawn in a GDI+ overlay pass in
   `MapViewport.RenderSimulationSpeechBubbles`, executed after `renderer.Render`, so the
   exact same pass serves the GDI+ and D3D11 renderers. `D3D11Renderer.Render(Graphics g)`
   uses `g` only for interface compatibility and never draws text.
5. **Backwards-compatible Advance.** The original `Advance(long)` signature is preserved
   and now delegates to `Advance(long, Location, bool)` with no player, so every existing
   validator and call site behaves exactly as before (no aggro). Production wiring passes
   the live GOD player via `MapViewport.GodPlayer` from `MapTabPage.AdvanceSimulation`.

## 4. Safety invariants (inherited from Plan 3 §3)

The awareness path never writes `OtCreature.Location`, never adds/removes creatures,
never mutates spawns, never creates actions or undo entries, never saves simulated
positions, and never creates tiles. `IngameCreatureState` owns only fresh `Location`
instances.

## 5. Acceptance criteria

1. A monster within ±11, on the same floor, with a clear line acquires the GOD player.
2. A monster out of range (beyond ±11) or on another floor does not acquire / loses the target.
3. An inactive GOD player never triggers aggro.
4. A chasing monster moves toward the player without a spawn-zone restriction.
5. A monster stops advancing once within its `targetDistance`.
6. A monster without a `<voices>` block never speaks.
7. A monster with `<voices>` speaks after `speed|interval`, gated by `chance`, and
   renders a bubble labelled SAY (white) or YELL (orange).
8. `Advance(long)` with no player reproduces the pre-awareness random-walk behaviour.
9. All Plan 3 safety invariants still hold; fingerprints unchanged.

## 6. Focused validation

Run:

1. `dotnet build SharpMapTracker/SharpMapTracker.csproj -c Release --no-restore`
2. `dotnet SharpMapTracker/bin/Release/net10.0-windows/LegacyXEditor.dll --validate-ingame-simulation`

The validator now includes deterministic aggro (acquire / lose / re-acquire / first
chase step) and voices (no speech before interval, first-sentence yell emission).

## 7. Handoff statement

Only `hampusborgos/rme` `source/` (for editor rendering) and the local 10.91 server
`src/` (for awareness behavior) were used as external authorities. No other fork,
Canary, TFS, OTClient, blog or model memory was used as parity evidence.