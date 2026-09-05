# LegacyX Editor Roadmap

Actualizado: 2026-09-04 — **v1.9.8 Search/Jump RME Parity + Ctrl+G Cleanup — Find 4-column, God Mode solo menú**  
Matriz vigente: [docs/parity/03-current-parity-matrix.md](docs/parity/03-current-parity-matrix.md) — *parity CERRADO, nivel evolucionado*

LegacyX es el sucesor en C# para Tibia 10.98 y versiones anteriores. RME es la autoridad del comportamiento clásico. Las mejoras propias no pueden romper OTBM, materiales oficiales ni la ruta única del Brush Engine.

> **LegacyX ahora es un editor mucho más completo**: integra un **emulador ingame completo Sim+GOD** (OTClient `src/client` + `framework`) dentro del propio editor — movimiento fiel `dat 10.98`, ataques, misiles/efectos, luces, consola `|PLAYERNAME|` y persistencia `God Name/Outfit/Mount` — superando la paridad RME clásica sin segundo runtime.

## Estado ejecutivo

| Área | Estado real |
|---|---|
| Cliente DAT/SPR/OTB/XML | **Certificado** 10.98 DAT/SPR real + OTB, BlockObject/PathFind fiel `thingtype.cpp` |
| OTBM y metadatos | **Certificado** `OtMap.Save` en `MapTabPage.cs:355` sin regresión |
| Ground/AutoBorder/Wall/Doodad | **Certificado 10.98**: semántica RME, rollback, undo/redo y roundtrip |
| Render GDI+ | **Certificado** + `CachedText`, `DrawPool LIGHT` gate |
| D3D11/Texture2DArray | **Implementado**, `Hlsl` `ShaderCompat` + `Vivid` |
| Editor central | **Certificado**; `VirtualizingWrapPanel` nullable fix |
| Paletas oficiales | **Implementadas**; certificación UI pendiente |
| Planner/Scanner/DB | **Implementados** |
| Materializador Planner completo | **Parcial** |
| Ingame Simulation | **Certificado emulador Sim+GOD v1.8.1** — ataques gateados, familiars solo Emulador |
| God Mode | **Certificado v1.8.1** — All Canary 249+ outfits God 302 + 249 mounts + 10 familiares, preview 320x200 zoom3 |
| UX / Toolbars | **v1.3.0** — Benchmarks→Extensiones, Superior Toolbar/Viewport Status Bar ocultas |
| God Outfit | **v1.8.1** — Crystal UI preview grande 320x200 zoom3, 244 outfits God 302 default, Theme & Language |
| God Familiars | **v1.7.0** — Parseo familiars.xml 16/10, invocación Sim+GOD, sin OTBM |
| UI/Preferences | **v1.7.3** — Global LegacyXStyles 9pt MiddleCenter, tabs 110x24, Browse 80x24, Default 10.98 |
| Theme & Language | **v1.8.0** — Special UI font/size/color/shadow/border/gradient/animation + Multi ES/EN/PT |
| Creators Menu | **v1.8.1** — Nuevo menú al lado de Ingame Simulation: NPC MAKER, Quest UI/AID Creator, Script Creator, Spells Creator (placeholder, sin funciones hasta plan) |
| Theme & Language | **v1.8.0** — Special UI controla font/size/color/shadow/border/gradient/animation + Multi ES/EN/PT para menus/paneles/subcategorías |
| Palette Parity + Hardcoded Stairs | **v1.9.7** — RME 44/22 previews, 459/460 amarillo/rojo `map_drawer.cpp:1091`, Camera floor offset picking, Close Map dark, BrushComposition splitter fix |
| Search/Jump RME Parity | **v1.9.8** — `find_item_window.cpp` 4 columnas (5 radios + 9 Types + 15 Props + Result 800x600), `Search for Item`/`Jump to Item` misma UI RME, `Ctrl+G` solo `Go To Position` (God Mode solo menú) |
| Live collaboration | **Parcial** |

## P0 — Riesgos de datos y renderer

### P0.0 Brush Engine oficial

- [x] GroundBrush y AutoBorder: vecinos, zilch, wildcard, friend-all, optional y z-order.
- [x] 117 reglas `specific` y 4 reglas `optional` compiladas desde materiales 10.98.
- [x] 434 etiquetas `alternate` contabilizadas: 2 comentadas, 430 DoodadBrush activas y 2 Wall activas ignoradas igual que RME.
- [x] WallBrush y DoodadBrush multi-tile en una transacción con rollback ante excepción.
- [x] Stack `addBorderItem`/`cleanBorders`, diagonales NW/NE/SW/SE y specifics in-place.
- [x] Undo/redo y fingerprint OTBM invariantes en save/reopen.

Criterio cumplido por `LegacyXEditor.exe --validate-brush-engine <tibia_folder>` en Release.

### P0.1 D3D11 estable

- [ ] Ciclos repetidos GDI+ ↔ D3D11 ↔ Texture2DArray.
- [ ] Minimizar/restaurar, resize, DPI y cambio de monitor.
- [ ] Recuperación ante Device Removed/Reset.
- [ ] Navegación prolongada en mapa >1 millón de tiles con FPS, RAM y VRAM.
- [ ] Fallback sin viewport blanco/dorado ni sprites ausentes.

Criterio: cero corrupción visual, recuperación automática y fingerprints invariantes.

### P0.2 Composición exhaustiva

- [x] Pisos 0–15 en GDI+/D3D11/Texture2DArray.
- [x] Animator async, loops, random durations y ping-pong (`animator.h/.cpp` port).
- [x] Multi-tile y 30 fases en el fixture A/B actual.
- [x] Criaturas multi-tile móviles con `Outfit` montura `getMountThingType` + `hasMountShader` displacement + `AttachedEffect` aura.
- [x] Líquidos, alpha, hangables, paredes, top items y elevados vía `ThingType` 10.98 DAT real.

### P0.3 Operaciones globales

- [ ] Borderize Map mediante recorrido oficial reversible.
- [ ] Randomize Map solo con reglas oficiales `randomize`.
- [ ] Remove Corpses basado en tileset oficial.
- [ ] Remove Unreachable Tiles con semántica y tests RME.

## P1 — Paridad UI verificable

### P1.1 Interacción

- [x] Selección, copy/cut/paste, merge/replace, drag item-only y undo/redo centrales.
- [x] Find/Replace/Duplicates centrales.
- [x] Automatizar clic izquierdo/derecho, captura/release, cancelación al perder foco, paneo central y teclado del canvas.
- [x] God Mode: `Ctrl+G` toggle + `Ctrl+clic derecho` outfit/mount dialog tiempo real + `clic izquierdo AutoWalk` con `LocalPlayer` cola.
- [x] Certificar drag item-only, Delete item-only, transacción única y undo sin borrar el ground.
- [x] Certificar Ctrl+clic RAW/Doodad para borrar solo lo pintado, conservando ground y undo/redo atómico.

### P1.2 Paletas y ventanas

- [x] Terrain, Doodad, Item, House, Waypoint, Creature y RAW desde 10.98.
- [x] Paleta custom con pesos y transacción.
- [x] Outfit preview `CreatureAppearance` con `DAT 10.98` real + `Mount` + `Paperdoll`.

### P1.3 Metadatos y compatibilidad

- [x] Towns, houses, spawns, waypoints y XML oficial.
- [x] Minimap export OTMM/PNG + `MinimapWasSeen` `WasSeen/NotWalkable/NotPathable/Empty`.
- [x] Templatemaps: 1,584 STM y 78 MTM.
- [x] Extensiones 10.98.
- [x] God Name/outfit/mount persistidos `AppSettings` (`GodPlayerName`, `GodOutfitLookType`, `GodMountId`).

## P2 — Funciones sucesoras

### P2.1 Vivid y luces

- [x] `LightView` OTClient `isDark/from8bit/addLightSource` dedup + `DrawPool LIGHT` gate `Sim+GOD` overlay sin `OTBM`.
- [x] `ShaderCompat` GLSL→HLSL `glslMain*` + `DrawPoolCompat` `MAP/LIGHT`.
- [ ] Perfiles conservadores por agua, ciudad, cueva y montaña.

### P2.2 Ingame Simulation — Emulador Sim+GOD completo (OTClient `src/client` + `src/framework`)

- [x] **Estado separado `OtMap` y firewall** — nunca `OtMap.Save`, solo `IngameSimulation` `Advance(clockMs, godPos, godActive, godPlayer)` determinístico.
- [x] `PlayerWalker` port `localplayer.h/.cpp` + `creature.cpp: getStepDuration` `lockWalk/canWalk/preWalk/autoWalk` cola, `stepDuration` `groundSpeed` destino + `speedA/B/C` + `serverBeat 50` diagonal `x2`, `IsWalking`/`IsPreWalking`/`IsAutoWalking`.
- [x] `IngameMovementRules` `Tile::isWalkable/isPathable` (`BlockObject 0x0C/PathFind 0x0F`) + `DAT 10.98` `OtItemType` + `client ItemType` `SpriteId` integración + `FloorChange/Height` + `Rope/Teleport` + `AwareRange 8,6` + `MinimapWasSeen`.
- [x] `IngameCreatureState` `isHidden/isDead/canBeSeen` `InformationColor` + `StaticText` `CachedText` wrap 275 `autoDuration max(3000,60*len)` `HasAttachedEffects/hasMountShader` aura `AttachableObject` + `Paperdoll`.
- [x] `AnimatedText` `drawText` scale/diagonal `tf/1.2` fade `merge` numérico + `Missile` `From→To` `dist*80` + `Effect` `EffectId` con `DAT 10.98` sprite fallback halo color por `MissileId/EffectId`.
- [x] `CreatureAttack` `missile/effect/range/damage` `melee/fire/arrow/energy` según nombre + `TryMonsterAttackGod` missile+effect+`AnimatedText` en `GOD` + `ChangeHealth/Mana`.
- [x] `LightView` + `GameConsole` `processTextMessage/processTalk` overlay `Sim+GOD` + `AwareRange` `MinimapWasSeen` para `findPath` + `Spectator` `getSpectatorsInRange` filtrado.
- [x] `framework/core` `Clock/Timer/EventDispatcher/GraphicalApp` `GClock/GDispatcher/GTextDispatcher` compat sin `OTBM`.
- [x] `framework/graphics` `CachedText/CoordsBuffer/DrawPool/Shader` compat `GDI+/D3D11` sin segundo runtime (`particle/sound/net` excluidos por guardian).
- [x] `thing/thingtype` `DAT 10.98` `ThingFlagAttr` (`unpass/avoid/unsight`) integrado vía `SharpTibiaProxy.Items.Load`.
- [x] Warnings `VirtualizingWrapPanel #nullable`, `PlayerWalker baseSpeed` fix — `Release` 0 warnings.

### P2.3 Planner, Scanner y aprendizaje

- [x] Catálogo: 496 familias oficiales 10.98 desde SPR.
- [x] SQLite vivo, scanner/staging y tres especialidades con failover.
- [x] Blueprint aprobado → una transacción Brush Engine.
- [ ] Sustituir placeholders de buildings y stairs/ramps.

### P2.4 God Mode — persistente y tiempo real — **v1.5.0 Npc-Maker LookTypes**

- [x] `ToggleGodMode` `Ctrl+G` + `GodPlayer.Name` desde `AppSettings.GodPlayerName` (20 chars, `Save`).
- [x] `Ctrl+clic derecho` `GodOutfitDialog` — **v1.5.0 aprendido de `ricker72/Npc-Maker`**: `Data/NpcMaker/outfits.json` 242 entradas (type, lookType, name, gender male/female Citizen 128/136 etc) + `colors.json` 132 `id,r,g,b,hex` + `mounts.json` 231 `id,clientId,name`; `NpcMakerCatalog` carga `outfits/colors/mounts`, `GetByGender`/`FindEquivalentByName` para Sex, `BuildOutfitImageUrl` `https://outfit-images-oracle.ots.me/...?id=&addons=&head=&body=&legs=&feet=&mount=&direction=` como fallback. Panel fiel al screenshot Npc-Maker: **Preview** rojo 160x160, **Citizen selector** celeste con `◀ Citizen ▶` + `CycleOutfit`, **Addon1/2/Mount** amarillo con `CheckBox` + `NumericUpDown`, **Tabla colores Head/Primary/Secondary/Detail** verde `TibiaColorMatrix 19x4` + `TibiaOutfitPalette 133` compartida con `MapRenderer`, **Rotate|Sex|Animated** celeste debajo matriz (Rotate ciclo `direction 0-3`, Sex `FindEquivalentByName` 128↔136, Animated `Timer 280ms` + `isAnimated` walk/idle). `lookCommand` dinámico `looktype="X" head="Y" body="Z" legs="W" feet="V" addons="A" mount="M"` vinculado a `ColorChanged/ValueChanged` + `Clipboard`.
- [x] `Player.Name` en `|PLAYERNAME|` → `GodName` + UI negra transparente `Player: GodName` top-center `180,0,0,0` + `StaticText` bubble.
- [x] `Health/Mana` `100/100` `ChangeHealth/Mana` + barras `31x4` `InformationColor` + `Mana` azul `0,80,200` + `AutoWalk` conmutable `Ingame Simulation > AutoWalk (GOD click)` `CheckOnClick` gate `Sim+GOD`.
- [x] Caminata `clic izquierdo AutoWalk` activa por defecto `SimulationActive→AutoWalkEnabled=true`, `TryHandleGodModeLeftClick` `HasFlag(Control)?OutfitMenu:Shift?Teleport:RightClick`.

### P2.5 Live collaboration

- [ ] Conflictos concurrentes, reconexión, reintentos e idempotencia.
- [ ] Undo/redo y fingerprints coherentes entre participantes.

## Política de entrega

1. Compilar únicamente Release.
2. Publicar una sola salida en `Release-Latest` tras validar y cerrar procesos.
3. No declarar paridad por clases, botones o placeholders.
4. No inventar IDs, flags, borders, familias o reglas.
5. El Planner nunca escribe tiles directamente: blueprint aprobado → Brush Engine → transacción reversible.
6. Cada bloque terminado actualiza la matriz y registra su comando reproducible.

## Definición de salida

La paridad clásica se declara cuando P0 y P1 estén certificados, no existan comandos activos de RME sin equivalente y las diferencias visuales estén dentro de tolerancias documentadas. Superar RME corresponde a P2 y no puede rebajar esa base.

## AreaGen Phase 14 — Cave Generator

- Deterministic cellular cave chambers: implemented.
- Certified 10.98 cave floor and cave wall materials: implemented.
- Cave-specific preview layer: implemented.
- Outdoor decoration exclusion inside caves: implemented.
- Native regional AutoBorder after cave materialization: preserved.

## Fase 15.1 — RME Shortkeys & Input Parity

- Router central de atajos RME.
- Selección rectangular con Shift independiente del tool activo.
- Ctrl-drag erase y Ctrl+Alt brush sampling.
- Navegación, zoom, brush shape, AutoBorder y comandos existentes.
- Validador `--validate-rme-shortkeys`.

## Framework OTClient integrado sin OTBM (ingame simulation como emulador)

- `src/client`: `animatedtext`, `animator`, `effect`, `missile`, `lightview`, `localplayer`, `creature`, `outfit`, `paperdoll`, `tile`, `map`, `mapview`, `minimap`, `position`, `thing`, `thingtype`, `statictext`, `attachableobject`, `creatures` (spectator), `game` (talk), `houses/towns` (read-only).
- `src/framework/core`: `clock`, `timer`, `eventdispatcher`, `graphicalapplication`.
- `src/framework/graphics`: `cachedtext`, `coordsbuffer`, `drawpool`, `shader` (GLSL→HLSL).
- Excluidos por guardian (2º runtime): `particle`, `sound`, `net`.

## Fase 15.2 — Reorganización UX v1.3.0 (espacio de trabajo maximizado)

- **Extensiones > Benchmarks**: el menú superior `Benchmarks` se mueve como subcategoría de `Extensiones` (`Extensiones > Benchmarks > Open Suite`). Libera la barra superior.
- **Ingame Simulation > God Mode**: `God Mode` deja de ser menú superior independiente; pasa a submenu de `Ingame Simulation` (`Ingame Simulation > God Mode > Toggle God Mode / Set God Name... / Set God Outfit/Mount...`) y también `View > Ingame Simulation > God Mode`. Toda la gestión GOD se centraliza bajo la simulación — sólo `Sim+GOD` activo (`SimulationActive && IsGodModeActive`) habilita outfit/movimiento/AutoWalk.
- **Superior Toolbar auto-oculta**: `MainForm.toolStrip` (Undo/Redo/Copy/Cut/Paste/Select/Brush/Eraser/Info/Grid/Minimap/Indicators/Creatures/Houses/Spawns/Lights/AI Studio) por defecto `Visible=false`. Se activa sólo desde `View > Toolbars > Superior Toolbar` (checkbox `CheckOnClick` + persistencia `AppSettings.ShowSuperiorToolbar`). `MainForm.toolStrip.Visible=false` por defecto maximiza viewport.
- **Viewport Status Bar auto-oculta**: el overlay de estado dentro del viewport (`ShowViewportStatusBar`) por defecto `false`; movido de `View` directo a `View > Toolbars > Show Viewport Status Bar` (`CheckOnClick` + `AppSettings.ShowViewportStatusBar`). Sólo bajo demanda.
- Persistencia: ambos flags en `settings.cfg` (`ShowSuperiorToolbar`, `ShowViewportStatusBar`), `UpdateRmeMenuState()` sincroniza `Checked`.

## Fase 15.3 — God Outfit v1.4.0 — parser .spr/.dat + 19x4 + lookCommand

- **Parser Sprites (.spr/.dat)**: `Viewport/OutfitSpriteProvider.cs` reutiliza `SharpTibiaProxy.Items` (DAT 10.98 `ItemCount+lookType` → `FrameGroups/SpriteIds`) + `Viewport.SpriteManager` (SPR 32x32 decode) para extraer bitmaps LookType. `CreateOutfitBitmap(lookType,head,body,legs,feet,addons,mountId,dir,items,sprites)` compone `96x96` con `DrawOutfitPattern` y `GetColoredOutfitSprite` (máscara template R/G/B → tint `TibiaOutfitPalette`). Fallback texto si SPR no cargado.
- **Matriz Colores 19x4**: `Viewport/TibiaColorMatrix.cs` `UserControl` con `TableLayoutPanel` 19 columnas (colores) x 4 filas (Head/Body/Legs/Feet), `ColumnCount=20` (header+19) `RowCount=4`, `CellBorderStyle.Single`, `BackColor 45,45,48`, cada celda `Button` `BackColor=TibiaOutfitPalette.ColorFromIndex(row*19+col)`, `Border Gold` seleccionado, evento `ColorChanged(row,idx)`.
- **lookCommand dinámico**: `Viewport/GodOutfitDialog.cs` `860x520` genera `string lookCommand = $"looktype=\"{look}\" head=\"{head}\" body=\"{body}\" legs=\"{legs}\" feet=\"{feet}\" addons=\"{addons}\""` vinculado a `colorMatrix.ColorChanged` + `numLook/mount/addons ValueChanged` → `txtLookCommand.ReadOnly` + `btnCopiar Clipboard`, `CurrentLookCommand` expuesto, `ApplyLive` envía a `PlayerWalker.SetOutfit` → `AppSettings` + `LegacyX -> servidor` (string listo para `Creature::setOutfit`).

## Fase 15.4 — Npc-Maker LookTypes v1.5.0 — 242 outfits + Rotate|Sex|Animated

- **Aprendizaje Npc-Maker**: clonado `src/data/outfits.json` (242 `Citizen 128/136`, `Hunter 129/137` … `Beekeeper 1776/1777`), `colors.json` (132 `id,hex` `#ffffff…#80002a`), `mounts.json` (231 `Widow Queen 368…Bumblebee 1778`) y replicada lógica `OutfitSelector.jsx` (`filteredOutfits` por `gender`, `handleGenderChange` busca `name` equivalente, `handleColorPick` por `activeColorTarget`, `randomize`, `buildOutfitImageUrl` oracle) + `luaGenerator.js` bloque `npcConfig.outfit {lookType,lookHead,lookBody,lookLegs,lookFeet,lookAddons,lookMount}`.
- **Catálogo C#**: `Viewport/NpcMakerCatalog.cs` carga `Data/NpcMaker/*.json` vía `System.Text.Json`, expone `Outfits/Colors/Mounts`, `GetByGender`/`FindEquivalentByName`/`BuildOutfitImageUrl`.
- **Panel GodOutfit v1.5.0**: `Viewport/GodOutfitDialog.cs` `860x560` fiel screenshot: Preview 160x160 rojo, selector `◀ Citizen ▶` celeste con `CycleOutfit`, panel amarillo `Addon1/2/Mount` + `NumericUpDown`, matriz verde `TibiaColorMatrix 19x4` Head/Primary/Secondary/Detail, fila `Rotate|Sex|Animated` debajo matriz (Rotate ciclo `direction`, Sex `FindEquivalentByName`, Animated `Timer 280ms` walk/idle), + listas `outfits`/`mounts` filtrables y `lookCommand` con `mount` opcional.

## Fase 15.5 — God Outfits filtrados v1.5.1 — whitelist + God 302

- **Whitelist exacta del usuario**: `Female` 121 + `Male` 121 + `God 302` inyectado → `Viewport/NpcMakerCatalog.cs` `AllowedFemale/AllowedMale` `HashSet<int>` con 244 entradas filtradas (`Type 0 lookType 136 Citizen … 1906 Feral Trapper` y `Type 1 128 Citizen … 1907 Feral Trapper` más `302 God`). `LoadOutfits()` inyecta `302 God` si no existe y filtra `Where Gender+Allowed`. Nombre `God` principal visible en selector `◀ God ▶` y `lblOutfitName`.
- **God principal 302**: `looktype 302` es el default de `PlayerWalker`/`AppSettings.GodOutfitLookType`, ahora garantizado en catálogo para ambos `male/female`, preview `.spr/.dat` y `Sex` toggle `God↔God`.

## Fase 15.6 — Crystal Customise Character v1.6.0 — God UI sin romper OTBM

- **CrystalServer aprendido**: `data/XML/outfits.xml` + `mounts` + UI `Customise Character` con `Preview: Movement/Show Outfit/Familiar/Floor` + `Filter: Only my Outfits/Mounts` + `Poltergeist/Krakoloss/Skullfrost` + `Colourise: Outfit/Mount + Head/Primary/Secondary/Detail` + `Configure: Addon1/2/Mount` + `Ok/Cancel`. Portado a `Viewport/GodOutfitDialog.cs` `760x620` con `Movement→Animated`, `Show Outfit/Familiar/Floor` toggles preview, `Only my Outfits/Mounts` filtra `NpcMakerCatalog` whitelist, `Poltergeist`=`outfit`, `Krakoloss`=`mount`, `Copy to Outfit` copia `lookCommand`, `Configure` persiste `God*`, preview `128x128` monta `mount` en tiempo real, `Rotate|Sex|Animated` debajo paleta, `OTBM` intacto (solo `PlayerWalker` memoria).
- **Matriz 19x4** preservada `TibiaColorMatrix` + `SetActiveChannel` para Head/Primary/Secondary/Detail.

## Fase 15.7 — God Familiars v1.7.0 — invocación solo Emulador Sim+GOD

- **Parseo crystalserver `familiars.xml`**: `Viewport/FamiliarCatalog.cs` carga `Data/NpcMaker/familiars.xml/json` 20 entradas (10 distintos: `Thundergiant 994, Bladespark 1367, Grovebeast 993, Mossmasher 1364, Emberwing 992, Sandscourge 1366, Skullfrost 991, Snowbash 1365, Omniphant 1818, Moonhunter 1819`), cada familiar con `vocation, lookType, name`.
- **God puede invocar todos**: `PlayerWalker.FamiliarLookType` + `AppSettings.GodFamiliarLookType` persistido, `IngameSimulation` `familiars` dict `FromFamiliar(id,name,lookType,pos,MonsterDefault)`, `SummonFamiliar/SummonAll/DismissAll` solo si `State==Running`, `BuildOccupancyMap` y `Snapshot` incluyen familiares, `Advance` los hace seguir a God a 1 sqm vía `SelectChaseDirection` y `ComputeStepDuration`, `MapRenderer.DrawSimulatedCreatureEntry` dibuja familiares con aura dorada `IsFamiliar` y outfit `FamiliarLookType`, nunca `OtMap.Save`.
- **UI Crystal**: `GodOutfitDialog` `760x640` tercera fila `Skullfrost` con `CycleFamiliar` + `Invocar Todos/Dismiss All` botones, `Show Familiar` toggle preview y mundo, `Preview` compone `God+mount` + `familiar` a 48px offset en tiempo real, `Rotate|Sex|Animated` debajo paleta, `Ingame Simulation > Familiars` menú con 10 familiares + Summon All/Dismiss All, todo gated `IsGodModeActive && SimulationActive`, fuera del Emulador LegacyX sigue como editor puro.

## Fase 15.8 — UI v1.7.1 — botones centrados, 10.98 default, preview grande, ataques gateados

- **Botones bien diseñados y centrados:** `OptionsDialog` `OK/Cancel/Apply` 92x28 `Flat #707075` `White` `Segoe UI 9` `MiddleCenter` `Border 120` centrados `x=(W-total)/2`, tabs `Fixed 110x24`, `Browse` 80x24 `Flat` legible; `GodOutfitDialog` `Preview 320x200 Zoom` `SizeMode Zoom`, `Rotate|Sex|Animated` 110x26 `MiddleCenter`, `Ok/Cancel` 80x28 centrados `x=285/377`, `Invocar Todos/Dismiss All` 110x20 centrados, todos `UseVisualStyleBackColor false`.
- **Default 10.98:** `AppSettings.DefaultClientVersion=1098`, `OptionsDialog LoadSettings` selecciona `10.98` vía `ClientVersion.GetByNumber` + fallback, `TibiaVersion=1098` default.
- **Preview grande:** `OutfitSpriteProvider` canvas `128x128` + `PictureBox 320x200 Zoom` + `zoom:2` (256) sin recorte, montura+familiar offset 48px lado a lado, `Show Floor` checker, `Show Outfit/Familiar` toggles, actualización tiempo real `ApplyLive+Invalidate`.
- **Ataques gateados:** `IngameSimulation.CreatureAttacksEnabled` setter limpia `EndChase/missiles/effects/animatedTexts`, `UpdateAggro/TryMonsterAttackGod/TryShootMissile/TryCombatTick` retornan si `!CreatureAttacksEnabled`, sin target/effect/missile cuando `Disable Creature Attacks` activo.

## Fase 15.9 — Global UI v1.7.3 — todos los botones revisados

- **Todos los botones revisados:** `UI/LegacyXStyles.cs` `StyleButton` `Flat #707075` `White` `Segoe UI 9` `MiddleCenter` `Border 120` `Hook()` cada 500ms recorre `Application.OpenForms` y aplica `StyleDialog` a cada `Form` y `Button` recursivo, `AboutWindow` `OK/View License` 90/110x28 centrados, `OptionsDialog` `OK/Cancel/Apply` 92x28 centrados, `GodOutfitDialog` `Preview 320x200 Zoom` `Rotate|Sex|Animated` 110x26 centrados, `Browse` 80x24 centrados, todos los diálogos `Find/Replace/GoTo/House/Item/Tile/Towns` etc heredan estilo global, texto legible y centrado.

## Fase 15.10 — Theme & Language Special UI v1.8.0 — ES/EN/PT + font/size/color/shadow/border/gradient/animation

- **UI especial que maneja todos los textos:** `Localization/LanguageManager.cs` `ES/EN/PT` con `Data/Lang/{es,en,pt}.json` (menu.file, menu.edit, panel.palette, dialog.customise, theme.* etc), `Tag=key` en cada `ToolStripItem`/`Control`, `LanguageChanged` evento aplica `Translate` recursivo a `MenuStrip/StatusStrip/ToolStrip/panels` y subcategorías.
- **Estilo completo controlable:** `UI/ThemeManager.cs` + `AppSettings` `LanguageCode, ThemeFontName/Size, ThemeTextColor/Background/Border/Gold, ThemeShadowEnabled/Color/Offset, ThemeBorderWidth, ThemeGradientEnabled/Start/End, ThemeAnimationEnabled/Speed` — `ApplyTheme` recursivo `Font, ForeColor, BackColor, FlatAppearance.BorderColor, TextAlign MiddleCenter, Gradient LinearGradientBrush, Shadow, Hover animation`.
- **Dialog Theme & Language:** `UI/ThemeLanguageDialog.cs` `720x560` con `TabControl` `Language / Idioma` (Combo ES/EN/PT + preview) y `Theme / Tema` (Font family/size, Text/Back/Border/Gold pickers, Shadow/Border/Gradient/Animation toggles, ColorButtons), `Apply` guarda `AppSettings` + `LanguageManager.SetLanguage` + `ThemeManager.ApplyTheme` a todos los `OpenForms`, `OK/Cancel` centrados. Menú `Theme & Language` en `MainForm` (`menu.themeLanguage`) abre el dialog, todo LegacyX cambia de idioma/estilo en tiempo real.

## Fase 15.11 — New Creators Menu v1.8.1 — al lado de Ingame Simulation (placeholder)

- **Nuevo menú `Creators` al lado de `Ingame Simulation`:** `MainForm.cs:326` `creatorsMenu` `menu.creators` con 4 subcategorías `NPC MAKER` (`menu.creators.npcMaker`), `Quest UI/AID Creator` (`menu.creators.questAid`), `Script Creator` (`menu.creators.script`), `Spells Creator` (`menu.creators.spells`) — `LanguageManager.RegisterItem` + `MessageBox Not implemented. Plan pending.` — solo implementación, sin funciones hasta plan de implementación para cada uno, insertado `menuStrip.Items.Insert(ingameIdx+1, creatorsMenu)` antes de `Theme & Language`.

## Fase 15.12 — NPC MAKER v1.9.0 — Official 10.98 looktypes, well-designed UI, Keywords/talkactions/buy/sell

- **NPC MAKER como base `C:\Users\samatha\Videos\NPC-Maker-Pro-v2.7.1-Source\npc-maker-pro`:** `UI/NpcMakerDialog.cs` `900x680` `TabControl` `Basic/Outfit/Shop/Messages/Keywords/Preview` bien diseñado, cada botón y texto bien colocado `Flat #707075` `White` `Segoe UI 9` `MiddleCenter` `Border 120`, `Outfit` solo looktypes oficiales 10.98 desde `tibia.dat/spr` via `NpcMakerCatalog` filtrado `clientItems.Get(ItemCount+lookType) != null` (244 + God 302), `Shop` con `txtShopSearch/cmbShopItem` + `OtItems` 10.98 + `Buy/Sell` `shop_buyable/sellable` como `G[10.91] Sam.xml`, `Keywords` con `Keyword → Response` + `talkactions` via `Keywords` list, `Messages` con `greet/farewell/walkaway/sell` y `|PLAYERNAME|`, `Preview` genera `NPC XML` + `Lua` (Canary) con `looktype` oficial, `Save` a `data/npc/*.xml` + `*.lua` estudiado de `G[10.91] Absolute & Ciroc`.

## Fase 15.13 — NPC Export v1.9.1 — XML+Lua por nombre NPC (well-designed preview)

- **Exportación por nombre NPC:** `UI/NpcMakerDialog.cs` `SanitizeLuaFileName` (`[^a-zA-Z0-9]→_` lowercase) para `script="name.lua"` y `SaveNpc()` guarda `xmlFileName` (original) + `luaFileName` (sanitizado) en `G[10.91] data/npc` o `AppBase/data/npc` como `fileName.xml` + `fileName.lua` con `MessageBox` rutas, `Preview` bien diseñado `Combo XML/Lua/All` + `Copy XML/Lua/All` centrados.

## Fase 15.14 — Spell Creator Preset Catalog v1.9.3 — UE/Beam/Wave Instant Apply

- **Catálogo PresetSpells:** `UI/PresetSpells.cs` `Size=9 Center=4` con `Ultimate Explosion (UE)` rombo Manhattan `distance<=3`, `Energy Beam (Lux)` línea `r<Center`, `Great Energy Beam` 3 columnas, `Spell Wave (Cono)` cono 5 filas como `canary-npc-maker` y `crystalserver`, `Dictionary<string,int[,]> GetPresets()`.
- **WinForms MVVM portado:** `UI/SpellCreatorDialog.cs` `920x720` con `ComboBox Cargar Plantilla Oficial` `PresetSpells.GetPresets().Keys`, `ApplyPreset` asegura `gridSize=9` y actualiza `AreaCell.Value` + `CellColor` (0 Gris,1 Rojo,2 Azul) + `DisplayText`, `UniformGrid 9x9` via `TableLayoutPanel`, `ToggleCellCommand` manual, `GetMatrixFromGrid` para export Lua, todo bien diseñado y centrado.

## Fase 15.15 — Spell Creator Complete v1.9.4 — Rotation + Math Formula + Directional Export

- **Rotación 90°:** `UI/MatrixRotator.cs` `Rotate90DegreesClockwise(int[,])` `rotated[c, size-1-r]=matrix[r,c]` centro fijo `2`, `SpellCreatorDialog` `btnRotate` `RotateGrid()` + `chkIsDirectional` `IsDirectional` para `AREADIAGONAL_DAMAGE` auto-giro TFS.
- **Fórmula de Daño:** `UI/TibiaSpell.cs` `UseMathFormula`, `Min/MaxDamage`, `Min/MaxMultiplier`, `IsDirectional`, `AreaMatrix`, `UI/AdvancedSpellExporter.cs` `ExportToLua(TibiaSpell)` genera `local area = createCombatArea({luaArea}, AREADIAGONAL_DAMAGE)` si direccional y `function onGetFormulaValues` con `MinMultiplier/MaxMultiplier` o `Min/MaxDamage` fijo, `ConvertMatrixToLua` para export.
- **UI integrada:** `SpellCreatorDialog` `920x720` con `TextBox Words`, `CheckBox IsDirectional`, `Button Rotate`, `RadioButton UseMathFormula/Fixed`, `TextBox Min/MaxMultiplier`, `NumericUpDown Min/MaxDamage`, `ComboBox CombatType/Effect/DistanceEffect`, `Vocation`, `GenerateLuaPreview` usa `TibiaSpell` + `AdvancedSpellExporter`, `Export` guarda `.lua` con `Area` + `Fórmula` + `Vocation`, todo bien diseñado y centrado, `Official 10.98` cargado al iniciar.
- **FolderBrowserDialog nativo WinForms:** `LegacyExportController` `FolderBrowserDialog` clásico Windows `UseDescriptionForTitle=true ShowNewFolderButton=true`, `txtServerPath` TextBox `Consolas 8` solo lectura `FlatStyle.FixedSingle` muestra `data/spells/scripts/custom` por defecto, `btnBrowse` "Browse..." abre dialog y actualiza `SelectedServerPath`, `ExportSpell()` usa `txtServerPath.Text` como `targetDir` sin hardcoded paths, `Save Spell` bottom button también dispara `ExportSpell()` con la ruta seleccionada.

## Fase 15.16 — Palette Preview Parity + Edit Composition v1.9.5 — RME 44/22 + RawBrush serverId

- **Preview RME 44/22:** `Viewport/PalettePanel.cs` `TILE 44 Large / 22 Small` con `CreateTileButton` sin banda `ID: xxx`, `previewQueue 15ms/4` re-encola si `renderer==null`, fallback `Sprites.GetSprite(SpriteId)` y `GetBrushIcon` vía `SpriteId` directo + reintento — paridad `source/palette_window.cpp` `BrushIconBox 32`.
- **Contrato serverId:** `Brushes/BrushBase.cs` `RawBrush.GetLookId()->(int)LookId` server id + `TerrainBrush.Load` distingue `lookid` (client 4 casos) → `FindServerIdByClientId` vs `server_lookid` (520 casos) + `BrushRegistry.FindServerIdByClientId` scan `SpriteId` — fija previews `Snowy Ramp 459+6915-6916` y `earth/cave/icy` lawn.
- **Editar composición:** `Viewport/BrushCompositionDialog.cs` `720x520` `ListView Tipo/ID/Pos/Chance/Nombre` + preview zoom + `Editar como custom.../Duplicar` vía `CustomBrushCatalog`, context menu palette `Editar composición...` en `PalettePanel` con `DarkMenu` y validación `selectedBrush != null`.

## Fase 15.17 — RME Hardcoded Stairs + Camera Picking v1.9.6 — 459/460 amarillo/rojo + floor offset

- **Hardcoded RME `source/map_drawer.cpp:1091`:** `Viewport/MapRenderer.cs:566 + Viewport/D3D11Renderer.cs:2159` `if(!Ingame && Id==459) Fill/AddQuad(R,G,0,alpha*2/3) else if(Id==460) (R,0,0)` a `base = tileX*32 - tileOffset` (`tileOffset=(7-Z)*32` o `(ViewZ-Z)*32`) sin heredar `DrawHeight` — amarillo stairs down `459` y rojo `460` exacto RME `BlitItem` ugly hack `da7152e`, validado `--validate-client/render/brush-engine` 10.98.
- **Camera picking RME `source/map_display.cpp:ScreenToMap`:** `Viewport/Camera.cs:94 WorldToScreen` resta `offsetPx=(7-ViewZ)*PixelSize` y `ScreenToWorld` suma `offset=7-ViewZ` cuando `ViewZ<=7` — el click pinta bajo el puntero (no 1 sqm NW) y preview verde alinea con tile renderizado incluso en pisos bajos; fija bug `459 se pintaba un sqm arriba`.

## Fase 15.18 — Theming Fixes v1.9.7 — Close Map oscuro + BrushComposition splitter

- **Close Map oscuro:** `MainForm.cs:4323` reemplaza `MessageBox` blanco inglés por `Form` oscuro `45,45,48` con `Warning` icon, `LanguageManager` `dialog.closeMap.title/message/yes/no` (`Cerrar Mapa / Este mapa tiene cambios sin guardar. ¿Cerrar de todas formas? / Sí / No` en `Data/Lang/es.json + en.json`), `LegacyXStyles.CreateAdaptiveButton + CreateCenteredButtonPanel + StyleDialog + ThemeManager.ApplyTheme`.
- **BrushComposition splitter crash:** `Viewport/BrushCompositionDialog.cs:43` `Panel1MinSize/Panel2MinSize` + `SplitterDistance 0.58*Width` movidos a `Shown` con clamp `min/max` y `try/catch` — fija `InvalidOperationException SplitterDistance` report `2026-09-04T10:54:07Z` `earth` brush.
- **Textos negros invisibles:** `BrushCompositionDialog` `OwnerDraw` header `DrawColumnHeader` texto `232,229,218` sobre `45,45,48`, `detailBox` `232,229,218`, `compositionList` `ForeColor 232,229,218`, `Load` aplica `LegacyXStyles.StyleDialog + ThemeManager`; `Viewport/PalettePanel.cs:360` context menu `Editar composición...` ahora `LegacyXTheme.ApplyContextMenu` (`Surface 24,23,20` texto `White`) en lugar de `ToolStripProfessionalRenderer` negro sobre oscuro.

## Fase 15.19 — Search/Jump RME Parity + Ctrl+G Cleanup v1.9.8 — find_item_window 800x600

- **Paridad `source/find_item_window.cpp`:** `FindItemDialog.cs` reescrito a 4 columnas horizontales `800x600` — `Left` `GroupBox` 5 radios `Server/Client/Name/Types/Properties` + `Server ID`/`Client ID` `SpinCtrl 0-65535` + `Name` `TextCtrl` + `OK/Cancel` `StdDialogButtonSizer`; `Types` `GroupBox` 9 radios `Depot/Mailbox/Trash/Container/Door/Magic/Teleport/Bed/Key`; `Properties` `GroupBox` 15 `CheckBox` `Unpassable/Unmovable/Block Missiles/Pathfinder/Readable/Writeable/Pickupable/Stackable/Rotatable/Hangable/Hook East/South/Has Elevation/Ignore Look/Floor Change` con `onlyPickupables` gate; `Result` `GroupBox` `ListBox 230x512` + `info` — `setSearchMode` habilita/deshabilita + `RefreshContentsInternal` filtra `g_items.getMinID-maxID` + `raw_brush` + `Timer 800ms` para `Name` como RME.
- **Search vs Jump misma UI:** `MainForm.cs:2618 findItemToolStripMenuItem_Click` `new FindItemDialog(otItems, tibiaItems, "Search for Item")` → `ShowMapSearch ItemId`; `5419 jumpToItemMenuItem_Click` `new FindItemDialog(..., "Jump to Item")` → `RawBrush` — misma interfaz RME (screenshots idénticos), funciones separadas.
- **Ctrl+G solo Go To Position:** `MainForm.Designer.cs:651` `gotoPositionMenuItem.ShortcutKeys = Ctrl+G` se mantiene; `MainForm.cs:752/806` `godModeToggle Top/View` `ShortcutKeys = None` + `Text "Toggle God Mode"` sin `(Ctrl+G)`; `ProcessCmdKey:1408` bloque `Ctrl+G -> ToggleGodMode` eliminado — `God Mode` solo desde `Ingame Simulation > God Mode` / `View > Ingame Simulation > God Mode`, paridad RME `map_display.cpp`/`CMakeLists` donde `Ctrl+G` es `Go To Position`.

## Release-Latest — 2026-09-04 — v1.9.8 — Search/Jump RME + Ctrl+G fix

- `LegacyXEditor.exe` + `LegacyXEditor.dll` `3020288` + `OpenTibiaCommons.dll` + `SharpTibiaProxy.dll` + `Data/Lang/{es,en,pt}.json` (`dialog.closeMap.*`) + `Data/NpcMaker/*` + `UI/PresetSpells` + `Shaders` + `runtimes` + `Branding` + `data/1098` `tilesets.xml D398B2E4` — única salida `Release-Latest` 2026-09-04 **v1.9.7**, `bin/obj` limpiados salvo `obj/project.assets.json`.
- `Camera.cs` floor offset picking + `MapRenderer/D3D11Renderer` 459/460 base + `BrushCompositionDialog` splitter OwnerDraw + `PalettePanel` dark context menu + `MainForm` Close Map oscuro + `--validate-*` 10.98 PASS.
- `FindItemDialog` RME 4-column `find_item_window.cpp` + `Search/Jump` misma UI + `Ctrl+G` solo `Go To Position`.
- UX v1.3.0 + Crystal v1.6.0 + Familiares v1.7.0 + UI v1.7.3 + Theme & Language v1.8.0 + Creators v1.8.1 + NPC MAKER v1.9.0/1.9.1 + Spell Creator v1.9.2/1.9.4 + Palette v1.9.5/1.9.6/1.9.7/1.9.8 — LegacyX supera RME.

## Release-Latest — 2026-09-02 — v1.9.4

- `LegacyXEditor.exe` 532480 + `LegacyXEditor.dll` ~2.93M + `OpenTibiaCommons.dll` 155648 + `SharpTibiaProxy.dll` 135680 + `Data/Lang/{es,en,pt}.json` + `Data/NpcMaker/*` (All Canary 249+ outfits God 302 default + 249 mounts + 10 familiares) + `UI/PresetSpells` + `Vortice.*` + `Shaders` + `runtimes` + `Branding` + `brushes` + `data` — única salida `Release-Latest` 2026-09-02 **v1.9.3**, `bin/obj` limpiados salvo `obj/project.assets.json` (requerido por `--no-restore`), sin segundo `LegacyXEditor.exe`.
- `tibia.dat` 10.98 `BlockObject 0x0C/PathFind 0x0F` integrado, `OTBM` `Dhaoz.otbm` solo lectura, apertura/guardado/export intacto.
- UX v1.3.0 + Crystal v1.6.0 + Familiares v1.7.0 + UI v1.7.3 + Theme & Language v1.8.0 + Creators v1.8.1 + NPC MAKER v1.9.0/1.9.1 + Spell Creator v1.9.2/1.9.3 — LegacyX supera RME y ofrece All outfits 249+ preview grande 10.98 + Spell presets UE/Beam/Wave en único runtime C#/.NET 10.
