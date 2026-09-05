# Informe final de auditoría técnica — LegacyX Editor

Preparación para la integración del módulo **AreaGen** (generación procedural de mapas).

- Fecha: 2026-08-05
- Alcance: solo lectura; no se modificó ningún archivo de código, configuración o datos.
- Prohibiciones respetadas: sin compilación, sin Git, sin OTMapGen/Node.js, sin `appearances.dat`, sin invención de clases o rutas.
- Convención de conclusiones:
  - **CONFIRMADO**: evidencia directa en el árbol fuente local.
  - **INFERENCIA**: derivado de evidencia, pero no verificado en runtime.
  - **NO ENCONTRADO**: no existe en el árbol actual.
  - **REQUIERE PRUEBA EN WINDOWS**: la fuente no desambigua y la validación requiere ejecutar el Release.

---

## 1. Resumen ejecutivo

LegacyX Editor es una aplicación **C#/.NET 10 / Windows Forms** que reimplementa Remere's Map Editor (RME) para Tibia 10.98. La arquitectura ya contiene un subsistema de generación procedural (Planner) con catálogo material certificado, motor de brushes oficiales y frontera de transacción única. El módulo **AreaGen** debe construirse sobre esas rutas existentes: resolver materiales vía `PlannerVisualCatalog`, mutar exclusivamente a través de los brushes oficiales dentro de una `BatchAction`, y abrir el resultado como una `MapTabPage` nueva con el patrón de `GuiService.NewMap`.

No se detectó ningún bloqueo para la integración. Hay una inconsistencia documental (planos referenciados que no existen) y una brecha de política (operaciones globales deshabilitadas) que deben resolverse antes de implementar AreaGen como feature de menú.

---

## 2. Ciclo 1 — Inventario general de la solución

**CONFIRMADO.**

- Solución: `SharpTibiaProxy.sln` con 5 proyectos:
  - `SharpTibiaProxy` (Library, `net10.0-windows`, `UseWPF=true`, BouncyCastle 2.6.2): cliente Tibia, DAT/SPR, red.
  - `OpenTibiaCommons` (Library, ref SharpTibiaProxy, `EmbeddedResource` de `Data/TemplateMaps/*.map`): modelo de mapa y OTBM.
  - `SharpMapTracker` (WinExe, `AssemblyName=LegacyXEditor`, `StartupObject=SharpMapTracker.Program`, refs a los dos anteriores): editor.
  - `SharpMapTrackerServer` (Exe): servidor auxiliar.
  - `TibiaCastDownloader` (Exe `net10.0`): utilidad externa.
- NuGet en SharpMapTracker: `Microsoft.Data.Sqlite`, `SQLitePCLRaw.bundle_e_sqlite3`, `Vortice.Direct3D11/DXGI/D3DCompiler`, `Vortice.Mathematics`, `XbrzSharp`.
- Punto de entrada: `Program.cs:31` `static int Main(string[] args)` con `[STAThread]` y `Application.SetHighDpiMode(PerMonitorV2)`.
- `data/` contiene carpetas por versión (740…1098) con `materials/grounds/borders/doodads/tilesets/walls/creatures.xml` + `items.otb`/`items.xml`.
- `Release-Latest/` es un artefacto de política manual (AGENTS.md), no de MSBuild. No se toca.

---

## 3. Ciclo 2 — Menú principal y comando Generate Map

**CONFIRMADO.**

- `MainForm.Designer.cs:297`: menús File, Edit, Map, Select, View, Window, Floor, About.
- `MainForm.Designer.cs:314`: File → New, Open, Load Sprites, Change Client Folder, Save, Save As, **Generate Map** (línea 322), Close, Import, Export, Reload, Recent Files, Preferences, Exit.
- `MainForm.cs:855` `CreateCommand(ActionIdentifier)` delega a handlers `_Click`.
- `CommandRegistrar.cs` registra comandos en `CommandManager.Instance` con `Func` a tab/mapa/toolmanager/actionqueue/copybuffer/viewport actuales.
- `MainForm.cs:2969` `generateMapToolStripMenuItem_Click` → `PlannerArchitect_Click`.
- `data/menubar.xml` es referencia de validación, NO se carga en runtime (cero referencias en `.cs`).
- **NO ENCONTRADO**: los planos `docs/plans/01-rme-menu-palette-drag-parity.md` y `docs/plans/02-rme-full-source-successor-planner.md` referenciados en AGENTS.md/opencode.json. Solo existe `03-ingame-successor-simulation.md`.

---

## 4. Ciclo 3 — Mapa y documento activo

**CONFIRMADO.**

- `MapTabPage.cs`: contenedor por pestaña; expone `Map`, `Viewport`, `ActionQueue`, `ToolManager`, `CopyBuffer`, `OtItems`, `MapFilePath`, `SaveMap(file, isSaveAs)`.
- `OpenTibiaCommons/Domain/OtMap.cs`: modelo central. Diccionarios `tiles` (`ulong` key), `creatures`, `spawns`, `towns`, `houses`, `waypoints`; índice espacial `QTreeNode spatialIndex`; `Width/Height` (`ushort`); `Version`, `MajorVersionItems`, `MinorVersionItems`, `HouseFile`, `SpawnFile`.
- `OtMap` API relevante: `GetTile/SetTile/GetOrCreateTile/RemoveTile`, `GetBounds`, `GetEmptyTownId/GetEmptyHouseId`, `AddSpawn`, `DoChange/ClearChanges` (marcas de modificación), `Save/Load`.
- `OtTile.cs`: `Ground`, `Items` (stack ordenado), `Creature`, `Spawn`, `MapColor`, `HouseId`, `MapFlags` (`TileMapFlags`), `SetLocation`.
- `Location.ToIndex()` (SharpTibiaProxy): packing X/Y/Z (16/16/8 bits) para la clave del diccionario.

---

## 5. Ciclo 4 — Modelo OTBM y persistencia

**CONFIRMADO.**

- `OtMap.Save/SaveOtbm` (línea 552), `SaveSpawns` (690), `SaveHouses` (811), `Load` (877), `ParseTileArea` (1034), `ParseTowns` (1158), `ParseWaypoints` (1177), `LoadSpawn` (1195).
- Serialización binaria en `OpenTibiaCommons/IO/`: `OtFileWriter/OtFileReader`, `OtPropertyWriter/OtPropertyReader`, `OtFileNode`.
- Roundtrip OTBM/XML certificado (`--validate-map-roundtrip`): headers, descripciones, flags, HouseId, stacks ordenados, contenedores, teleports, doors/depots, towns, houses, waypoints, spawns, tiempos/direcciones y extensiones XML desconocidas preservadas.
- Paridad de política: mapa real `Dhaoz.otbm` (1,045,077 tiles) autorizado solo como entrada de solo lectura; ediciones sobre copia temporal.

---

## 6. Ciclo 5 — Viewport: cámara, entrada y render

**CONFIRMADO.**

- `Camera.cs`:
  - `TileSize = 32` (línea 10); `Zoom` 0.125×–4.0×; `ViewZ` 0–15.
  - `ScreenToWorld:94` y `WorldToScreen:104` con `Math.Floor`.
  - `GetVisibleTileRange:114` (margen −1/+2 tiles).
  - `CreateTransformMatrix:128` para GDI+.
- `MapViewport.cs` (1,794 líneas):
  - Entrada de ratón: `OnMouseDown:1268` — middle o left+Alt = pan; left → god mode o `toolManager.HandleMouseDown`; right → god mode o `HandleContextClick`. `Capture=true` mantiene la acción viva fuera del canvas.
  - `OnMouseMove:1315`, `OnMouseUp:1348`, `OnMouseDoubleClick:1333`, `OnMouseWheel:1473`, `OnLostFocus`/`OnMouseCaptureChanged` → `CancelTransientInput`.
  - Teclado: `OnKeyDown:1502` → `ProcessRmeCanvasKey:1519` (PageUp/Down, * / , flechas, `[`/`]` tamaño de brush, Z/X variación, Ctrl+`0`/`.`/`,` zoom, Delete selección, Ctrl+G god mode). `MainForm.ProcessCmdKey` llama al mismo método para robustez de foco.
  - `MoveByRmeArrow:1622`: flechas mueven cámara (1 tile @ zoom 1.0, 3 tiles en otro zoom, 10 con Ctrl) o al jugador en god mode.
  - Render: `MapRenderer` (GDI+, 1,624 líneas) y `D3D11Renderer` (2,560 líneas) detrás de `IRenderer`; `SwitchRenderer:769`; `EnsureRenderer:880`.
  - Eventos: `TileClicked`, `TileDoubleClicked`, `TileDragged`, `CameraChanged`, `RendererChanged`.
- `MapRenderer.cs`:
  - `Render:192` pipeline por capas; `RenderTileAt:404`; `DrawItem:501`; `RenderCreature:863`; `RenderGrid:727`; indicadores, luces, ghost de pisos superiores, overlay de simulación y minimap.
  - `clientIdToItemType` resuelto por `InitializeItemTypeMap:177`.

---

## 7. Ciclo 6 — MiniMap

**CONFIRMADO.**

- `MiniMap.cs` (`UserControl` 192×192):
  - 1 tile/pixel, centrado en `CenterLocation`, clamped a `Map.Width/Height`.
  - Color por tile = `tile.MapColor`; si falta tile y `HighlightMissingTiles` → fucsia.
  - View box blanco según zoom (`Camera.TileSize * camera.Zoom`) y offset de piso (`floorOffset`).
  - Clic izquierdo → `MiniMapClick` → centra el viewport (`MainForm.cs:1227`).
  - Export OTMM v1/PNG certificado; import deshabilitado (N/A RME).

---

## 8. Ciclo 7 — Transacciones, deshacer y herramientas

**CONFIRMADO.**

- `ActionSystem.cs`:
  - `TileSnapshot.Capture:124` captura Ground, Items, HouseId, MapFlags, Creature, Spawn; `Restore:138`.
  - `Change` (Before/After), `Action` (grupo de changes), `BatchAction` (grupo de actions, una operación de undo).
  - `ActionQueue`: `MaxUndoLevels=200`, `StackingDelayMs=500`; `BeginBatch:396`/`AddAction:401`/`EndBatch:436`; `Undo:467`/`Redo:481`; eventos `StateChanged`/`BatchCommitted`.
- `ToolManager.cs` (1,118 líneas): `SelectionTool`, `BrushTool` (`ApplyBrush:712` → `brush.Draw`), `EraserTool`, `InformationTool`; `SetTool:1013`, `SetBrush:1035`; `HandleMouseDown/Move/Up/ContextClick/ContextRelease`.
- `CopyBuffer.cs`: `Copy/Cut/Paste` (merge/replace/item-only), `BuildBufferTile:288`, `EnsureSurroundingTiles:307`.
- `Selection.cs` (254 líneas): selección de tiles/items, arrastre.

---

## 9. Ciclo 8 — Motor de brushes oficiales

**CONFIRMADO.**

- `BrushBase.cs` (855 líneas): `EditorBrush` abstracto con `Draw(OtMap, OtTile, ActionQueue)` / `Undraw` / `CanDraw` / `GetLookId` / `GetItemIds`. 19 implementaciones:
  - `TerrainBrush` → `RawBrush`, `GroundBrush`, `WallBrush`, `TableBrush`, `CarpetBrush`.
  - `DoorBrush` (abrir/cerrar, `SwitchDoor:467`), `CreatureBrush`, `SpawnBrush` (radio), `HouseBrush`, `HouseExitBrush`, `FlagBrush`, `WaypointBrush`, `OptionalBorderBrush`, `EraserBrush`.
- `BrushRegistry.cs` (470 líneas): registro único por id/nombre; `LoadFromXml:155`; `LoadOfficialTilesets:163`; `CreateGroundBrush/WallBrush/DoorBrush/RawBrush`; `Search:423`; `AddDefaultBrushes:385`.
- `TileBrushOps.cs`: `Borderize/Wallize/Tableize/Carpetize`; resolvers `GetGroundBrush/WallBrushFor/...`; `TryGetSwitchedDoor:138`.
- `OfficialMaterials.cs` (1,209 líneas):
  - `OfficialMaterialLoader.Load:96` compila materials XML → brushes oficiales.
  - `AutoBorderEngine` (`Borderize:594`, `Offsets` 3×3 en 561, `AddEdge:724`, reglas `FindBorder:769`, `AreFriends:791`, specifics).
  - `OfficialWallBrush` (`Align:989`, `AlignNeighbours:1007`), `OfficialDoodadBrush` (variaciones/partes ponderadas, `DrawChoice:1136`), `OfficialGroundBrush` (pesos + BorderRefs).
- Patrón de transacción de los oficiales: capturar región → mutar → `Restore` en caso de error → una `Action`/`BatchAction`.

---

## 10. Ciclo 9 — Planner y generación procedural existente

**CONFIRMADO.**

- `ArchitectPlan.cs`: `RegionPlan` (RegionId, ZoneType, Bounds, Floor, Biome, Density, Roads, Buildings, ForbiddenFamilies), `ArchitectPlan.Validate:138`, `GetTotalBounds:153`.
- `ChunkedBuilder.cs` (529 líneas): `PartitionIntoChunks:178`, `BuildChunk:111`, builders `BuildTerrainChunk:202`/`RoadChunk:232`/`WallChunk:288`/`NatureChunk:364`/`DecorationChunk:400`/`StructureGroup:263`; `RequireCertifiedFamily:424`; `ReservedTileSet` para evitar solapamiento.
- `BermoMapPlanner.cs`: `Trace(size=176):40` genera blueprint procedural (rutas, coastas, massifs, cuencas de lava/barro/tar, parches, bandas) con `StableHash(seed,x,y):462`; `PaintRoute:431`.
- `PlannerVisualCatalog.Compile(BrushRegistry, otItems, tibiaItems, materialsPath)`: **resolver material certificado** (496 familias SPR); usado en `MainForm.cs:1013`.
- `PlannerMaterializer.cs` (578 líneas): `ApplyApproved:64` y `ApplyChunk:144`; `FinalizeConnectedBrushes:242` (Autoborder/Wall); `MaterializeOptionalBorders:281`; conectores verticales `MaterializeVerticalConnectors:301`; `Restore:511`/`RestoreRegion:518`/`CaptureRegion:528`; una sola `BatchAction`.
- `PlannerWorkflow_ApplyRequested` (`MainForm.cs:1170`): punto de integración demostrado — aplica plan aprobado al mapa actual con un único batch y rollback.
- `GuiService.NewMap():521`: crea `OtMap` + `MapTabPage` "Untitled"; patrón a reutilizar para abrir el resultado de AreaGen.
- Generador CLI existente: `--generate-bermo` (`Program.cs:106`).

---

## 11. Ciclo 10 — Validadores Release

**CONFIRMADO.**

~30 validadores en `Program.cs` (`Main` línea 31), ejecutables contra `LegacyXEditor.dll`:

| Flag | Objetivo |
|---|---|
| `--validate-client` | DAT/SPR/OTB/XML 10.98 (530 brushes, 11,187 entradas) |
| `--validate-brush-engine` | Ground/AutoBorder (117 specific, 4 optional, 434 alternate) |
| `--validate-custom-brush-palette` | Paleta custom / pinceles compuestos |
| `--validate-palettes-menus` | Superficie de menús y paletas |
| `--validate-render` / `--validate-render-ab` / `--validate-map-render` / `--validate-window-render` | Render GDI+/D3D11 A/B |
| `--validate-gpu-textures` / `--validate-d3d11-recovery` / `--validate-animator` | D3D11 y animación |
| `--validate-map-roundtrip` / `--validate-map-locations` | OTBM/XML roundtrip y QTree |
| `--validate-input-interactions` / `--validate-selection-transaction` | Entrada y transacciones |
| `--validate-global-operations` / `--validate-minimap-export` / `--validate-item-properties` | Operaciones globales, minimap, propiedades |
| `--validate-planner-catalog` / `--validate-planner-core` / `--validate-planner-vertical-actions` / `--validate-planner-prompts` / `--validate-planner-providers` / `--validate-planner-model-discovery` | Planner |
| `--validate-ingame-simulation` / `--validate-diagnostics` / `--validate-extensions` / `--validate-template-maps` | Simulación, diagnóstico, extensiones, templates |
| `--inspect-map-readonly` / `--inspect-map-items-readonly` | Inspección de solo lectura |
| `--generate-bermo` | Generador CLI de prueba (Bermopolis) |
| `--validate-town-rules` / `--validate-creature-render` | Town rules y criaturas |
| `--show-gpu-texture-probe` | Sonda de texturas GPU |

---

## 12. Ciclo 11 — Evidencia RME autoritativa

**CONFIRMADO.**

- Snapshot local del permiso único: `C:\Users\samatha\AppData\Local\Temp\opencode\rme-reference` con el árbol `hampusborgos/rme` en `master`, commit `da7152ec94031c76732e997de4624c8f1c010225`.
- Archivos clave presentes: `editor.cpp`, `gui.cpp`, `map.cpp`, `basemap.cpp`, `tile.cpp`, `map_display.cpp`, `map_drawer.cpp`, `ground_brush.cpp`, `wall_brush.cpp`, `doodad_brush.cpp`, `brush.cpp`, `brush_tables.cpp`, `palette_window.cpp`, `palette_brushlist.cpp`, `minimap_window.cpp`, `carpet_brush.cpp`, `creature_brush.cpp`, `house_brush.cpp`, `spawn_brush.cpp`, `waypoint_brush.cpp`, `eraser_brush.cpp`, `graphics.cpp`.
- Prohibido usar cualquier otro fork, Canary, OTClient, TFS o wiki como evidencia de paridad.

---

## 13. Ciclo 12 — Estado de paridad (reporte vigente)

**CONFIRMADO** (leído `docs/parity/03-current-parity-matrix.md`, 2026-08-03).

- **Certificado**: DAT/SPR/OTB/XML, OTBM roundtrip, QTree, Render GDI+, Animator, D3D11/Texture2DArray/batching, pisos 0–15, Ground/AutoBorder, Wall/Doodad/Carpet/Raw, paletas oficiales, paleta custom/compuestos, selección/copy/paste, Find/Replace/Duplicates, Minimap export, Towns/Houses/Spawns/Waypoints, Template maps, Extensiones, Planner catálogo/DB/scanner, superficie de menús.
- **Implementado**: overlays, transparencia/prioridades, Vivid/iluminación, propiedades/menú contextual, signs/books/blackboards, Ingame Simulation.
- **Parcial**: Live collaboration, Planner materialización E2E, Planner sucesor, menús globales de mapa.
- **Bloqueado**: Reload/Recent/Automagic (requieren dueño de estado y especificación).
- **N/A RME**: Edit Items/Edit Monsters, import minimap.
- **Brechas para 100%**: UI real restante (DPI/multimonitor), fixtures exhaustivos de prioridades/alpha/hangables/líquidos, operaciones globales deshabilitadas, live collaboration, conectores verticales E2E, proveedores online sin secretos.

---

## 14. Ciclo 13 — Hallazgos para la integración de AreaGen

1. **Frontera de mutación única (CONFIRMADO)**: toda escritura debe pasar por los brushes oficiales (`BrushRegistry` + `OfficialMaterials`) dentro de una `BatchAction` (`ActionSystem`). Prohibido escribir tiles directamente.
2. **Resolución de materiales (CONFIRMADO)**: `PlannerVisualCatalog.Compile(...)` + `BrushRegistry.GetBrush` son el resolver certificado; AreaGen no debe inventar IDs ni flags.
3. **Salida del generador (CONFIRMADO)**: patrón `GuiService.NewMap()` — `OtMap` nuevo + `MapTabPage` — es la ruta para abrir un mapa generado; `--generate-bermo` demuestra que ya existe un generador CLI.
4. **Transacciones atómicas (CONFIRMADO)**: `PlannerMaterializer.ApplyApproved/ApplyChunk` con `CaptureRegion`/`RestoreRegion` y digest de fingerprint es el modelo de referencia para materializar un área con undo/redo y rollback.
5. **Reutilización de validadores (CONFIRMADO)**: `--validate-map-roundtrip`, `--validate-brush-engine` y `--validate-planner-core` son las barreras de entrada para cualquier cambio nuevo.
6. **Determinismo (CONFIRMADO)**: `BermoMapPlanner.StableHash(seed,x,y)` y `ChunkedBuilder` con `Random` sembrado establecen el patrón para semillas reproducibles.
7. **NO ENCONTRADO**: planos `01-rme-menu-palette-drag-parity.md` y `02-rme-full-source-successor-planner.md` (referenciados en AGENTS.md/opencode.json). Debe decidirse si se crean o se actualizan las referencias.
8. **REQUIERE PRUEBA EN WINDOWS**: rendimiento de generación a escala (>1M tiles) y comportamiento de DPI/multimonitor del resultado.

---

## 15. Riesgos y recomendaciones

### Riesgos
1. **Autoborder/wall contiguos**: una generación masiva debe finalizar bordes con `AutoBorderEngine` y `AlignNeighbours`; de lo contrario el mapa generado no cumple la paridad visual de brushes.
2. **Memoria**: mapas de >1M tiles con snapshots por tile pueden saturar el `ActionQueue`; usar `MaxUndoLevels` y batches por región.
3. **Semántica de pisos**: el generador debe respetar floors 0–15 y la exclusión de `Hole`/`RopeSpot`/`Sewer`/`InstanceTeleport` sin ground de llegada (política vigente del Planner).
4. **Política de datos**: nunca fabricar IDs; todo desde `items.otb`/materials 10.98 certificados.

### Recomendaciones (orden de trabajo sugerido)
1. Resolver la inconsistencia documental de los planos 01/02 (crear o corregir referencias).
2. Definir el contrato de AreaGen sobre `ArchitectPlan` + `RegionPlan` existentes.
3. Implementar AreaGen como librería de planificación + materialización que consuma `PlannerVisualCatalog` y los brushes oficiales.
4. Abrir el resultado con el patrón `GuiService.NewMap` en una pestaña propia.
5. Validar con `--validate-map-roundtrip`, `--validate-brush-engine` y un validador nuevo `--validate-areagen`.

---

## 16. Mano de obra ejecutada

- 13 ciclos de auditoría (inventario, menú, documento/mapa, OTBM, viewport, minimap, transacciones, brushes, Planner, validadores, evidencia RME, paridad, hallazgos).
- Sin compilación, sin Git, sin modificación de archivos del proyecto.
- Autoridad externa única: `hampusborgos/rme` `master` `da7152ec94031c76732e997de4624c8f1c010225` (snapshot local `%LOCALAPPDATA%\Temp\opencode\rme-reference`).
- No se usó ninguna otra fuente externa de compatibilidad (ni forks, ni Canary, ni OTClient, ni TFS, ni wikis).
