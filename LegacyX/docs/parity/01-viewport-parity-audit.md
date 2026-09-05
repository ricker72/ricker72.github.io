# Fase 1.2 — Auditoría Viewport: LegacyX Editor vs Remere's Map Editor

> **Auditoría histórica.** El estado vigente está en [03-current-parity-matrix.md](03-current-parity-matrix.md). Este documento conserva la evidencia original, no el estado actual completo.

- **Fecha**: 2026-08-01
- **Tipo**: auditoría solo lectura (no se escribió código, no se compiló)
- **Fase**: 1.2 de la ruta de paridad (Viewport Parity)
- **Objetivo**: equivalencia funcional del viewport completo — cámara, flujo de render, eventos de entrada (ratón/teclado), orden de dibujo, ciclo de invalidación y pestañas — contra la fuente autoritativa de RME.

---

## 1. Autoridad y alcance

### Fuente autoritativa RME

- Repositorio: `https://github.com/hampusborgos/rme`
- Rama/commit: `master` — SHA `da7152ec94031c76732e997de4624c8f1c010225` (2024-05-05)
- Snapshot plano local de inspección: `C:\Users\samatha\AppData\Local\Temp\opencode\rme-reference\`
- Archivos RME inspeccionados:
  - `source/map_display.h` / `map_display.cpp` (MapCanvas: ctor/Reset L107-155, Refresh L156-163, SetZoom L165-184, GetViewBox L186-191, OnPaint L193-253, ScreenToMap L339-366, GetScreenCenter L376-381, UpdatePositionStatus L388-431, OnMouseMove L441-580, OnWheel L1480-1533, OnKeyDown L1554-1760, OnMouseCameraClick/Release L1235-1275, ChangeFloor L2191-2202, EnterDrawing/SelectionMode L2204-2219, AnimationTimer L2553-2580)
  - `source/map_window.h` / `map_window.cpp` (MapWindow: composición L26-53, GetViewStart/GetViewSize L112-123, SetScreenCenterPosition L138-166, Scroll/ScrollRelative L173-193, FitToMap L125-129, OnScroll/OnSize L200-245)
  - `source/map_drawer.cpp` (Draw L220-236, DrawBackground L238-251, getFloorAdjustment L253-259, DrawShade L261-281, DrawMap L283-390, DrawHigherFloors L618-651, DrawGrid L546, DrawSelectionBox L653, DrawBrush L746, DrawIngameBox L482, DrawTile L1424-1552, BlitItem L1075/1191)
  - `source/gui.cpp` (RefreshView L1166-1189, ChangeFloor/GetCurrentFloor L1433-1451, GetCurrentZoom/SetCurrentZoom L488-501, FitViewToMap L503-521, UpdateMinimap L1142-1151, NewMapView L764, CycleTab L329)
  - `source/editor.cpp` (addAction L188-191, undo/redo L203-229 → RefreshView)

### Fuente local LegacyX

- Raíz: `C:\Users\samatha\OneDrive\Desktop\Editor Alpha\sharpmaptracker-master`
- Archivos C# inspeccionados:
  - `SharpMapTracker/Viewport/MapViewport.cs` (1568 líneas) — control, eventos, invalidación, timer de animación
  - `SharpMapTracker/Viewport/Camera.cs` (139) — modelo de cámara centrada
  - `SharpMapTracker/Viewport/MapRenderer.cs` (1522) — renderer GDI+, orden de dibujo
  - `SharpMapTracker/Viewport/IRenderer.cs` (55) — contrato renderer/DrawingOptions
  - `SharpMapTracker/Viewport/SpriteManager.cs` (206) — SPR + caché
  - `SharpMapTracker/Viewport/SpriteAnimator.cs` (241) — animación DAT
  - `SharpMapTracker/Viewport/ToolManager.cs` (1039) — SelectionTool/BrushTool/EraserTool/InfoTool
  - `SharpMapTracker/MapTabPage.cs` (423) — pestaña por mapa, suciedad, simulación, save
  - `SharpMapTracker/MainForm.cs` (4138) — tabs, status bar, minimap, floor menu, context menu
  - `SharpMapTracker/Services/GuiService.cs` (540) — GUI: ChangeFloor/RefreshView/Zoom/FitViewToMap/NewMapView

### Regla

- Ninguna otra fuente externa de paridad fue utilizada (prohibidos forks, Canary, OTClient, TFS, wikis, memoria de modelo).

---

## 2. Mapa del viewport (composición)

| RME (wxWidgets) | LegacyX (WinForms) | Notas |
|---|---|---|
| `MapWindow` (wxPanel): `MapCanvas` + `vScroll`/`hScroll` + `gem` | `MapViewport` (UserControl), sin scrollbars ni gem | RME expone la cámara como scrollbars; LegacyX usa cámara centrada |
| `MapCanvas` (wxGLCanvas) | `MapViewport` | dueño de input/render/refresh |
| `MapDrawer` (OpenGL) | `IRenderer` → `MapRenderer` (GDI+) / `D3D11Renderer` | dos implementaciones en LegacyX |
| `GameSprite`/`gfx` | `SpriteManager` + `SpriteAnimator` | animación portada (SpriteAnimator.cs) |
| `MapTab` (tabbook) | `MapTabPage` (TabPage) en `mapTabControl` | multi-view soportado en ambos |
| `g_gui` (GUI global) | `Services/GuiService` (GUI) | servicio estático `GUI` |
| `Editor` (actionQueue) | `OtMap` + `ActionQueue` + `ToolManager` | mutación vía batches |

### Modelo de cámara

- **RME**: scrollbar-based. `view_start` = thumbs de scrollbar (píxeles); `map_pixel = view_start + screen*zoom`; `ScreenToMap = (view_start + screen*zoom)/32` con rama para coordenadas negativas (map_display.cpp:339-366). `MapWindow::SetSize` fija el rango de scrollbar al tamaño del mapa en píxeles (`map.getWidth()*32`, map_window.cpp:85-97,125-129). Compensación de piso en `ScreenToMap` y `getFloorAdjustment` (map_drawer.cpp:253-259): para `floor <= 7`, `map += (7-floor)` y dibujo desplazado `(7-z)*32` px.
- **LegacyX**: center-based. `viewX/viewY` = tile central; `screen = halfW + (world - viewX)*pixelSize` (Camera.cs:94-126). `PixelSize = 32*zoom`. Sin scrollbars.
- **Zoom**: RME default `1.0`, clamp `[0.125, 25.0]` (map_display.cpp:167-170,1510-1517). LegacyX default `1.25f`, clamp `[0.125, 4.0f]` (Camera.cs:12,24).
- **Pisos**: ambos `0..15`; LegacyX `ViewZ` clamp `[0,15]` (Camera.cs:19); RME `ChangeFloor` clamp `[MapMinLayer, MapMaxLayer]` (gui.cpp:1445).
- **Offset de piso en la entrada**: RME compensa en `ScreenToMap` (map_display.cpp:359-365); LegacyX NO compensa en `Camera.ScreenToWorld`/`WorldToScreen`, pero el renderer SÍ aplica `tileOffset` al dibujar (MapRenderer.cs:274-282). → desalineación cursor→tile en pisos 0-6 (ver D-V3).

---

## 3. Flujo de render

### RME — `MapCanvas::OnPaint` (map_display.cpp:193-253)

1. `SetCurrent(GLContext)`.
2. Si render habilitado: poblar `DrawingOptions` desde settings (transparent floors/items, show grid, all floors, creatures, lights, only colors, preview…); `options.dragging = boundbox_selection`; arrancar/parar `AnimationTimer` según `show_preview || indicator`; `SetupVars(); SetupGL(); Draw();` screenshot opcional; `Release()`.
3. `g_gui.gfx.garbageCollection()` (texturas sin uso).
4. `SwapBuffers()`.
5. `editor.SendNodeRequests()` (live client).

### RME — `MapDrawer::Draw` (map_drawer.cpp:220-236)

1. `DrawBackground` (clear negro, blend).
2. `DrawMap` (L283-390): para `map_z` de `start_z` bajando a `superend_z`: `DrawShade(map_z)` si `map_z==end_z && start_z!=end_z`; si `map_z>=end_z`, caminar hojas de quadtree alineadas 4x4: por tile `DrawTile` (ground→items→creature, borders con tint), `AddLight` por tile; por hoja `DrawTileIndicators`; `DrawPositionIndicator(map_z)`; `DrawSecondaryMap(map_z)` (preview del pincel/paste); expandir rango ±1 por piso.
3. `DrawDraggingShadow`.
4. `DrawHigherFloors` (piso superior fantasma si `transparent_floors && floor!=0 && floor!=8`, L618-651; ground PZ en verde 128,255,128,96).
5. `DrawSelectionBox` (solo si `dragging`).
6. `DrawLiveCursors`.
7. `DrawBrush` (preview del pincel).
8. `DrawGrid` si `show_grid && zoom <= 10`.
9. `DrawIngameBox`.
10. `DrawTooltips` (GL).

### RME — `MapDrawer::DrawTile` (map_drawer.cpp:1424-1552)

- Skip si `show_only_modified && !tile->isModified()`.
- `getDrawPosition` (offset por piso).
- Tint: blocking (`g,b = g/3*2`), highlight_items por count, spawn `*0.7^n`, house `r/=2,g/=2` (o solo r si es la casa actual), PZ `r/=2,b/=2`, PVPZONE `g=r/4,b=b/3*2`, NOLOGOUT `b/=2`, NOPVP `g/=2`.
- `only_colors`: minimap color o cuadrado tintado.
- Si no: ground `BlitItem(draw_x, draw_y, tile, ground, false, r, g, b)` (tintado); items en orden de pila: borders `BlitItem(..., r,g,b)` (tintado), resto `BlitItem(...)` SIN tint; creature `BlitCreature` al final.
- Tooltip del ground/items solo cuando `position.z == floor`.

### LegacyX — `MapRenderer::Render` (MapRenderer.cs:179-389)

1. `g.Clear(backgroundColor)`; NearestNeighbor.
2. `camera.GetVisibleTileRange`.
3. `CreateTransformMatrix` (centro + zoom + traslación).
4. Bucle de pisos con `startZ/superendZ` espejando RME `SetupVars` (L204-215): shade si `ShowShade && z==endZ && startZ!=endZ` (L225-235); caminar nodos 4x4 alineados (L245-323): por tile `RenderTileAt` (ground + items, L391-429), `RenderCreature`, `RenderPlayer` (GOD); segunda pasada por hoja `RenderTileIndicatorsAt` (L301-321); criaturas simuladas por piso tras el grid (L336-343); expandir rango ±1 (L346-347).
5. `RenderHigherFloorGhost` si `TransparentFloors && floor!=0 && floor!=8` (L350-351).
6. `RenderGrid`.
7. `RenderSelectionHighlights`.
8. `RenderSimulationOverlay` (diagnóstico spawn/blocked).
9. Reset transform; `RenderLightOverlay`, `RenderGodModeSunlight`, `RenderMinimapOverlay`, `RenderIngameBox`.
10. Fuera del renderer: `toolManager.RenderOverlay` (preview del pincel, MapViewport.cs:1008-1015) y `DrawStatusBar` (L1030).

### Comparación de orden de dibujo

| Capa | RME | LegacyX |
|---|---|---|
| Fondo | clear negro | clear `BackColor` |
| Shade por piso | sí, igual gate | sí, igual gate |
| Tiles (ground→items→creature) | sí | sí |
| Indicadores por hoja 4x4 | segunda pasada | segunda pasada |
| Ghost piso superior | tras DrawMap | tras bucle de pisos |
| Selección | DrawSelectionBox (solo drag) | RenderSelectionHighlights (siempre si hay selección) |
| Brush preview | dentro de Draw, antes de grid/ingame box | DESPUÉS de todo el renderer (overlay separado) |
| Grid | si `show_grid && zoom<=10` | si ShowGrid, sin gate de zoom |
| Ingame box | tras grid | tras minimap/sunlight |
| Tooltips | dentro del render (GL) | ToolTip de WinForms (independiente) |

---

## 4. Eventos e invalidación ("quién invalida")

| Trigger | RME | LegacyX |
|---|---|---|
| Pintar (drag) | Brush aplica por tile; `OnMouseActionRelease` → `g_gui.RefreshView()` + `UpdateMinimap()` (map_display.cpp:1228-1233) | `BrushTool.ApplyBrush` invalida el viewport por aplicación (ToolManager.cs:692); `FinishDraw` → `ActionQueue.CommitBatch` → título (MapTabPage.cs:67-74) |
| Undo/Redo | `Editor::undo/redo` → `UpdateActions` + `RefreshView()` (editor.cpp:213-228) | MainForm invalida `CurrentViewport` + minimap (múltiples sitios) |
| Floor | `GUI::ChangeFloor` → `canvas->ChangeFloor` → `UpdatePositionStatus` + `UpdateFloorMenu` + `UpdateMinimap(true)` + `Refresh()` (map_display.cpp:2191-2202, gui.cpp:1440-1451) | `GUI.ChangeFloor` → `Camera.ViewZ` + `UpdateFloorLabel` + `UpdateStatusBar` + `RefreshView()` (GuiService.cs:341-356) |
| Zoom | `OnWheel`/`OnKeyDown` → ajuste de zoom anclado al cursor + `Refresh()` (map_display.cpp:1506-1530) | `OnMouseWheel` → `ZoomIn/ZoomOut` centrados + `Invalidate()` (MapViewport.cs:1296-1323) |
| Scroll | `MapWindow::OnScroll` → `Refresh()`; `ScrollRelative` → `UpdateMinimap()` (map_window.cpp:188-209) | sin scrollbars; pan con botón central |
| Mouse gain/lose | `OnGainMouse`/`OnLoseMouse` → reset drag states + `Refresh()` (map_display.cpp:1535-1552) | `OnLostFocus`/`OnMouseCaptureChanged` → `CancelTransientInput` + `Invalidate()` (MapViewport.cs:1267-1294) |
| Animación | `AnimationTimer` 100 ms; `Notify` redibuja solo si `zoom <= 2.0`; arranca/para desde `OnPaint` según `show_preview || indicator` (map_display.cpp:2553-2580) | Timer WinForms 33 ms; gate `zoom <= 4.0`; keep-alive `ShowPreview || SimulationActive` (MapViewport.cs:670-690, 893-927); además `SimulationTick` + `AdvanceGodWalk` |
| Cambio de pestaña | `tabbook`; `RefreshView()` pinta TODAS las pestañas de mapa | `SelectedIndexChanged` → focus + `UpdateIngameMenuState` (MainForm.cs:115-120); no invalida otras pestañas |
| Suciedad/título | `UpdateTitle` tras acciones | `OnActionQueueBatchCommitted` → `Map.DoChange` + título |

---

## 5. Entrada: ratón y teclado

### Ratón

| Gesto | RME | LegacyX |
|---|---|---|
| Left down | `OnMouseActionClick` (pintar/selección) | `ToolManager.HandleMouseDown` → `BrushTool.BeginBatch` + `ApplyBrush` (ToolManager.cs:537-552) |
| Left move | bucle de pintado + `RefreshView` limitado | `HandleMouseMove` → `ApplyBrush` + `Invalidate` (L554-560, 692) |
| Left up | `OnMouseActionRelease` → commit + `RefreshView` + `UpdateMinimap` | `HandleMouseUp` → `FinishDraw` + `CommitBatch` (L562-566) |
| Right down/up | `OnMousePropertiesClick/Release` → menú contextual/info | `HandleContextClick/Release` + evento `TileClicked` → menú contextual de MainForm (MainForm.cs:2343+) |
| Middle down | `OnMouseCameraClick` → `screendragging=true`; Ctrl+middle → zoom=1 anclado al cursor (L1242-1254) | middle → `isPanning=true`; Ctrl+middle → `Zoom=1.0` centrado (MapViewport.cs:1124-1141) |
| Middle move | `ScrollRelative(SCROLL_SPEED*zoom*dx)` + `Refresh` (L443-446) | `panViewStart - dx/pixelSize` tiles + `Invalidate` (L1171-1183) |
| Middle up | `OnMouseCameraRelease`: si <3 px → recentrar el punto clicado `ScrollRelative(zoom*(2c-sz))` (L1257-1275) | si no arrastró → `CenterOnTile(punto)` (L1224-1231) — misma semántica |
| Wheel | Ctrl → floor ±1 (rueda arriba = floor+1); Alt → brush size; si no → zoom continuo `zoom += -rotation*ZOOM_SPEED/640` anclado al cursor (L1480-1533) | Ctrl → `FloorDown/Up` (misma dirección); Alt → `StepBrushSize` (misma dirección); si no → ×1.25 centrado (L1296-1323) |
| Gain/Lose | reset drag + `Refresh` | `CancelTransientInput` + `Invalidate` |

### Teclado

| Tecla | RME | LegacyX |
|---|---|---|
| PageUp / Numpad+ | `ChangeFloor(floor-1)` | `PageUp`/`Oemplus` → `FloorUp` ✓ |
| PageDown / Numpad- | `ChangeFloor(floor+1)` | `PageDown`/`OemMinus` → `FloorDown` ✓ |
| Flechas | scroll `TileSize*tiles*zoom` px; `tiles=1` si zoom==1, si no 3; Ctrl=10 (L1630-1693) | `MoveByRmeArrow` mueve por tiles fijos (1/3/10), independiente del zoom (MapViewport.cs:1396-1436) |
| Numpad* / Numpad/ | zoom −0.3 / +0.3 anclado al cursor (L1571-1616) | `ProcessRmeCanvasKey` ejecuta zoom in/out ✓ |
| `[` / `]` y `+`/`-` | brush size (L1618-1629) | `ProcessRmeCanvasKey` avanza/retrocede el tamaño ✓ |
| Space / Ctrl+Space | `SwitchMode` / `FillDoodadPreviewBuffer` + `RefreshView` (L1694-1702) | `MainForm.ProcessCmdKey`: cambia modo/refresca preview ✓ |
| Tab | `CycleTab` (L1703-1710) | `MainForm.ProcessCmdKey`: recorre pestañas, Shift invierte ✓ |
| Delete | `destroySelection` + `RefreshView` (L1711-1715) | `MapOperations.DeleteSelection`: item-only, transacción única y undo ✓ |
| z/Z, x/X | variación de brush (L1716-1740) | variación oficial DoodadBrush con wrap ✓ |

---

## 6. Diferencias consolidadas (D-V1..D-V12)

### D-V1 — Zoom no anclado al cursor
- **RME**: `OnWheel` (map_display.cpp:1506-1529) ajusta `ScrollRelative(-scroll_x, -scroll_y)` con `scroll = screensize * diff * (cursor/screensize)` → el tile bajo el cursor permanece fijo. Teclado idem (L1581-1610).
- **LegacyX**: `OnMouseWheel` → `camera.ZoomIn/ZoomOut()` (MapViewport.cs:1315-1318) y `OnKeyDown` Ctrl+. / Ctrl+, (L1365-1382) → zoom anclado al CENTRO del viewport; el tile bajo el cursor se desplaza.
- **Aceptación**: hacer rueda sobre un tile concreto: ese tile debe permanecer bajo el cursor (RME) y hoy no lo hace (LegacyX).

### D-V2 — Rango/valor por defecto del zoom
- **RME**: default `1.0`, clamp `[0.125, 25.0]` (map_display.cpp:167-170,1510-1517).
- **LegacyX**: default `1.25f`, clamp `[0.125, 4.0f]` (Camera.cs:12,24).
- **Nota**: con clamp 4.0 el gate de grid `zoom<=10` (RME map_drawer.cpp:230) nunca se diferencia; no es observable hasta ampliar el rango. La comprobación del gate queda ligada a este D.

### D-V3 — Offset de piso no compensado en la conversión de entrada
- **RME**: `ScreenToMap` suma `MapGroundLayer - floor` para `floor <= 7` (map_display.cpp:359-365), y `getFloorAdjustment` desplaza el dibujo lo mismo (map_drawer.cpp:253-259) → cursor y dibujo siempre alineados.
- **LegacyX**: el renderer desplaza `drawX = tx*32 - (7-z)*32` para `z<=7` (MapRenderer.cs:274-282), pero `Camera.ScreenToWorld/WorldToScreen` NO compensan (Camera.cs:94-112) → en pisos 0-6 el tile que se ve centrado no es el tile que devuelve el cursor; las herramientas pintan/seleccionan un tile distinto del visual.
- **Aceptación**: en piso 5, centrar un tile conocido en pantalla y verificar que el cursor y el pincel apuntan al mismo tile dibujado (hoy falla por `7-z` tiles).

### D-V4 — `RefreshView` invalida solo la pestaña actual
- **RME**: `GUI::RefreshView()` recorre `tabbook` y refresca TODAS las pestañas de mapa (gui.cpp:1178-1188); `undo/redo` lo invocan (editor.cpp:214,228).
- **LegacyX**: `GuiService.RefreshView()` invalida solo `CurrentViewport` (GuiService.cs:381-386).
- **Consecuencia**: con dos vistas del mismo mapa (NewMapView), una vista no se repinta tras editar en la otra.
- **Aceptación**: abrir `NewMapView`, pintar en la pestaña A → la pestaña B debe mostrar el cambio sin interacción.

### D-V5 — Sin refresco forzado limitado (hard refresh)
- **RME**: `MapCanvas::Refresh()` hace `Update()` inmediato si `refresh_watch.Time() > HARD_REFRESH_RATE` + `Refresh()` asíncrono (map_display.cpp:156-163).
- **LegacyX**: solo `Invalidate()` asíncrono (WinForms); no hay throttling de refresco inmediato.
- **Impacto**: bajo (render GDI+ asíncrono); relevante solo si se busca cadencia de pintado idéntica durante arrastres.

### D-V6 — Cadencia y gate del timer de animación
- **RME**: `AnimationTimer` 100 ms; `Notify` redibuja solo si `zoom <= 2.0`; se arranca/para cada frame según `show_preview || position indicator` (map_display.cpp:230-233, 2553-2580).
- **LegacyX**: Timer 33 ms; gate `zoom <= 4.0`; keep-alive `ShowPreview || SimulationActive` (MapViewport.cs:670-690, 893-927); el mismo timer también ejecuta `AdvanceGodWalk` y `SimulationTick`.
- **Aceptación**: con preview activo, los ítems animados deben avanzar a 100 ms y detenerse sobre 200% de zoom (hoy avanzan a 33 ms hasta 400%).

### D-V7 — Tint aplicado a ítems no-border
- **RME**: `DrawTile` tiñe ground y ítems border con `(r,g,b)`; los ítems no-border se dibujan SIN tint (map_drawer.cpp:1516,1533-1537). El ghost de piso superior tiñe el ground PZ en verde `(128,255,128,96)` (L634-639).
- **LegacyX**: `DrawItem` pasa el tint (blocking/house/spawn/PZ/etc.) a TODOS los ítems vía `DrawTintedImage` (MapRenderer.cs:515-521, 650-678); el ghost usa tint blanco uniforme `(96,255,255,255)` (L1149).
- **Consecuencia**: paredes/objetos se oscurecen en LegacyX por shading de spawn/house/blocking cuando en RME permanecen a color.
- **Aceptación**: tile con spawn/house/blocking: solo ground + borders deben verse tintados (RME); hoy se tiñen también los ítems normales.

### D-V8 — Z-order del preview del brush y de la selección
- **RME**: `Draw()`: selección (si drag) → brush preview → grid → ingame box (map_drawer.cpp:220-236).
- **LegacyX**: grid → selection highlights → overlays → ingame box dentro del renderer; el preview del brush se dibuja DESPUÉS de todo en `OnPaint` (MapViewport.cs:1008-1015). La selección se dibuja siempre, no solo al arrastrar.
- **Consecuencia**: el pincel queda por encima del grid/ingame box en LegacyX; en RME queda debajo.

### D-V9 — Mapeo de teclado incompleto (zoom, brush size, modo, tabs, variación)
- **RME**: Numpad\*/Numpad/ zoom anclado, `[`/`]` y `+`/`-` brush size, Space `SwitchMode`, Ctrl+Space preview buffer, Tab `CycleTab`, z/x variación de brush (map_display.cpp:1618-1740).
- **LegacyX (resuelto 2026-08-03)**: `ProcessRmeCanvasKey` y `MainForm.ProcessCmdKey` cubren zoom, tamaño, Space, Tab, Delete y variación Z/X. `--validate-input-interactions` certifica la ruta del canvas en Release.

### D-V10 — Barra de estado: falta información del tile bajo el cursor
- **RME**: `UpdatePositionStatus`/`UpdateZoomStatus` escriben en la status bar (campos 1-3) pos, tile/ítem bajo el cursor y zoom (map_display.cpp:388-439), actualizados en cada mouse move.
- **LegacyX**: `DrawStatusBar` dibuja floor/zoom/pos en el viewport (MapViewport.cs:1098-1117) y `UpdateStatusBar` en MainForm solo en `CameraChanged` (MainForm.cs:2329-2341,2602-2617). No muestra el ítem bajo el cursor.

### D-V11 — Minimap: solo pestaña actual y sin update en floor/scroll global
- **RME**: `UpdateMinimap(immediate/delayed)` en floor change (map_display.cpp:2199), scroll (map_window.cpp:185,192) y refrescos.
- **LegacyX**: el minimap se re-centra vía `CameraChanged` (MainForm.cs:2334-2338) y `SetFloor` desde el minimap (L1271,1278). No se refresca en floor change de la GUI (solo status bar).
- **Impacto**: bajo; el minimap sigue al viewport, pero no replica los update de RME en todos los flujos.

### D-V12 — Ausencia de scrollbars / FitViewToMap por rangos
- **RME**: cámara = scrollbars con rango = tamaño del mapa en px, line/page scroll ±96/±5*96, `FitToMap` vía `SetSize` (map_window.cpp:85-129,200-245).
- **LegacyX**: cámara centrada sin scrollbars; `FitViewToMap` centra en el tile medio del bounding box (GuiService.cs:388-400).
- **Nota de alcance**: divergencia estructural deliberada; no bloquea paridad funcional de vista, pero debe documentarse como divergencia aceptada o decidirse en fase de UI.

---

## 7. Roadmap para cerrar Fase 1.2

Prioridad recomendada (cada ítem: evidencia RME + criterio de aceptación + validación enfocada).

1. **D-V4 — RefreshView multi-pestaña** (alto valor, esfuerzo bajo)
   - Dueño: `Services/GuiService.RefreshView` (GuiService.cs:381-386).
   - Implementar: invalidar todos los `MapTabPage.Viewport`, no solo el actual, espejando gui.cpp:1178-1188.
   - Validación: NewMapView → pintar en pestaña A → B se repinta sola.
2. **D-V1 + D-V2 — Zoom anclado al cursor y rango**
   - Dueño: `MapViewport.OnMouseWheel`/`OnKeyDown` y `Camera` (MapViewport.cs:1296-1382, Camera.cs:12-24).
   - Implementar: tras `ZoomIn/Out`, compensar la traslación para fijar el tile del cursor (fórmula de map_display.cpp:1526-1529); ampliar clamp a 25 y revisar el default (1.0 vs 1.25) con decisión explícita.
   - Validación: rueda sobre un tile → permanece fijo; zoom máximo llega a 2500%.
3. **D-V3 — Compensación de offset de piso en la entrada**
   - Dueño: `Camera.ScreenToWorld/WorldToScreen` o el viewport antes de despachar al `ToolManager`.
   - Implementar: para `ViewZ <= 7`, trasladar ±`(7-z)` tiles igual que RME `ScreenToMap` (map_display.cpp:359-365).
   - Validación: piso 5, pincel alineado con el tile dibujado (comparar visual y evento).
4. **D-V7 — Tint solo en ground + borders**
   - Dueño: `MapRenderer.DrawItem` (MapRenderer.cs:486-531).
   - Implementar: pasar tint solo a ground y `IsBorder`; ítems normales sin tint (map_drawer.cpp:1533-1537); ghost con verde PZ (L634-639).
   - Validación: comparación visual tile con spawn/house/blocking.
5. **D-V6 — Cadencia de animación 100 ms + gate 200%**
   - Dueño: `MapViewport` (MapViewport.cs:670-690).
   - Validación: avance de ítems animados a 100 ms; se congela sobre zoom 2.0.
6. **D-V8 — Z-order del preview del brush** (esfuerzo medio)
   - Dueño: `MapViewport.OnPaint` + renderer (MapViewport.cs:1008-1015).
   - Mover `toolManager.RenderOverlay` dentro del orden de RME (antes de grid/ingame box) o aceptar la divergencia.
7. **D-V5 — Throttle de refresco** (baja prioridad).
8. **D-V9 — Teclado** (depende de brushes; diferir a Fase 2.x para variación y a una fase de menús para Space/Tab/`[]`).
9. **D-V10 / D-V11 / D-V12** — documentar como divergencias aceptadas o resolver en fase de UI/pestañas (D-V12 requiere decisión de producto: mantener cámara centrada sin scrollbars).

Cada subfase debe seguir el guardián: evidencia RME → entrada C# → cambio mínimo → build `dotnet build SharpMapTracker/SharpMapTracker.csproj -c Release --no-restore` → validación enfocada → actualizar este informe antes de cerrar la diferencia.

---

## 8. Handoff

- **RME inspeccionado** (`da7152ec94031c76732e997de4624c8f1c010225`): `map_display.h/.cpp`, `map_window.h/.cpp`, `map_drawer.cpp`, `gui.cpp`, `editor.cpp`.
- **C# inspeccionado**: `MapViewport.cs`, `Camera.cs`, `MapRenderer.cs`, `IRenderer.cs`, `SpriteManager.cs`, `SpriteAnimator.cs`, `ToolManager.cs`, `MapTabPage.cs`, `MainForm.cs`, `Services/GuiService.cs`.
- **Resultado**: 12 diferencias (D-V1..D-V12), ninguna corregida todavía; auditoría 100% solo lectura.
- **Siguiente subfase recomendada**: D-V4 (RefreshView multi-pestaña).
- **Declaración explícita**: no se usó ninguna otra fuente externa de compatibilidad.

---

## 9. Corrección de regresión D3D11/Texture2DArray (2026-08-01)

- Evidencia de ejecución: `report-20260802-044143-117.json` registró que
  DAT, SPR y `Dhaoz-1098.otbm` cargaron correctamente antes de una
  `NullReferenceException` en `D3D11TileBatcher.Flush`.
- Causa: cuando fallaba una página `Texture2DArray`, el SRV recuperado desde el
  caché individual se enviaba incorrectamente al batch instanciado de arrays.
- Corrección: solo los SRV resueltos realmente desde una página se envían a
  `D3D11TileBatcher`; el fallo desactiva el experimento para esa instancia y
  conserva el caché individual. Una excepción posterior de frame D3D11 recupera
  el viewport con el renderer GDI+ existente.
- Los previews de paleta permanecen en `ClientItemPreviewRenderer`, compositor
  CPU independiente del renderer activo del viewport.
- Validación Release: build 0/0; `--validate-client`, `--validate-render`,
  `--validate-gpu-textures` y `--validate-map-render` sobre
  `Dhaoz-1098.otbm` pasaron. El A/B pasó a 12.5%, 100% y 400%.

---

## 10. P1 — Zoom, DPI y ciclo de ventanas (2026-08-02)

- Evidencia RME vigente (SHA `da7152ec94031c76732e997de4624c8f1c010225`):
  `source/map_display.cpp` (`SetZoom`, `GetViewBox`, `OnPaint`),
  `source/map_drawer.cpp` (`SetupVars`, `SetupGL`, margen visible) y
  `source/application.cpp` (`MapWindow::OnSize`).
- LegacyX selecciona ahora `HighDpiMode.PerMonitorV2` antes de crear cualquier
  HWND. `MapViewport` invalida el frame al cambiar DPI del padre y al recibir
  un tamaño cliente positivo; D3D11 conserva su dueño único y redimensiona el
  swap chain en el siguiente render.
- `--validate-d3d11-recovery` cubre cambio reiterado GDI+/D3D11, tamaños desde
  1x1, maximizar, minimizar/restaurar, perfiles físicos de `Screen.AllScreens`,
  DPI 96/120/144/168/192 y Device Removed/Reset.
- Nuevo `--validate-window-render <Tibia> <OTBM>` usa un recorte **en memoria**
  de tiles reales del mapa (no modifica el OTBM), captura el back buffer y
  exige dimensiones exactas y contenido distinto del clear color en 12.5%,
  25%, 50%, 100%, 125%, 200% y 400%, más perfiles DPI 96–192.
- Resultado Release: build 0 errores/0 advertencias; recuperación código 0;
  `terrenos.otbm` código 0; `Dhaoz-1098.otbm` código 0.
- Alcance honesto: el equipo de certificación sólo puede afirmar los monitores
  físicos devueltos por Windows en esa ejecución. Los restantes DPI se cubren
  mediante dimensiones físicas deterministas; no se declaran como monitores
  externos físicamente conectados.

---

## 11. Promoción del backend D3D11 (2026-08-03)

- Se retiró la etiqueta experimental de la UI y de los propietarios C# activos.
  `Texture2DArray` es ahora el batching D3D11 predeterminado en instalaciones
  nuevas; Vivid sigue siendo una elección explícita del usuario.
- Las claves antiguas `ExperimentalTextureArrayPages` y
  `ExperimentalVividRendering` sólo se aceptan al leer configuraciones previas.
  Al guardar se escriben `TextureArrayPagesEnabled` y
  `VividRenderingEnabled`.
- No se eliminó seguridad: si una página compacta falla, D3D11 conserva el
  caché por sprite; si falla el frame o el dispositivo no puede recuperarse,
  `MapViewport` mantiene el fallback GDI+ existente.
- Validación Release posterior a la promoción: compilación 0/0;
  `--validate-gpu-textures`, `--validate-d3d11-recovery`,
  `--validate-window-render`, `--validate-render-ab`,
  `--validate-creature-render` y `--validate-render-metrics` aprobaron.
- Captura A/B certificada en `Dhaoz-1098.otbm`: coordenada 281,261,11 a 125%;
  criaturas: 6,753 instancias, 212 apariencias resueltas desde 700 XML de
  monsters y 46 XML de NPC.
