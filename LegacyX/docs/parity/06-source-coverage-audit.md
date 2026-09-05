# Auditoría de cobertura RME → LegacyX

Fecha: 2026-08-10  
Autoridad única: `hampusborgos/rme/source`, commit `da7152ec94031c76732e997de4624c8f1c010225`.

Esta auditoría mide comportamiento observable, no coincidencia de nombres de
archivos. La matriz vigente sigue siendo `03-current-parity-matrix.md`; esta
documenta el trabajo que falta para que sus filas puedan declararse cerradas.

## Evidencia verificada

- RME: `source/editor.cpp`, `source/main_menubar.cpp`, `source/map.cpp` para operaciones globales y comandos.
- RME: `source/live_client.cpp`, `source/live_peer.cpp`, `source/live_action.cpp`, `source/live_server.cpp`, `source/live_packets.h` para Live Mapping.
- RME: `source/filehandle.cpp`, `source/iomap.cpp`, `source/iomap_otbm.cpp`, `source/iomap_otmm.cpp`, `source/item_attributes.cpp`, `source/complexitem.cpp` para persistencia.
- LegacyX: `SharpMapTracker/MainForm.cs`, `Viewport/MapOperations.cs`, `Viewport/ActionSystem.cs`, `Tracking/LiveMapTracker.cs`, `Share/Connection.cs`, `Share/MapShare.cs`, `Share/RmeLiveProtocol.cs`, `OpenTibiaCommons/IO/*`, `OpenTibiaCommons/Domain/OtMap.cs` y validadores de `SharpMapTracker/Program.cs`.

## Brechas de paridad confirmadas

| Prioridad | Alcance RME | Estado LegacyX | Brecha exacta | Cierre exigido |
| --- | --- | --- | --- | --- |
| P0 | `Editor::borderizeMap` + comando `MainMenuBar::OnBorderizeMap` | **Cerrado (Borderize Map)** | Implementado y certificado: `MapOperations.BorderizeMap` (editor.cpp:789-811, recorrido único in-place con progreso cada 4096 tiles), diálogo exacto Yes/No y refresh incondicional (main_menubar.cpp:1187-1197), predicado `has_map && !is_live` (main_menubar.cpp:321,355 con `LiveMapTracker.IsTracking` como análogo local de `IsLive`), sin entrada de historial ni `Map::doChange` (action.cpp:536,625,643). `--validate-whole-map-borderize` prueba la ruta real sobre copia temporal del mapa autorizado: count/grounds intactos, bordes en candidatos, no-undo y roundtrip. | No se publicó a `Release-Latest`. |
| P0 | `Editor::randomizeMap` y comando de `main_menubar.cpp` | **Cerrado (Randomize Map)** | `MapOperations.RandomizeMap` y `MainForm.randomizeMapMenuItem_Click` implementan el recorrido in-place sobre todos los tiles, ground brush oficial, preservación AID/UID, progreso cada 4096, confirmación exacta y no-undo. `--validate-whole-map-randomize` pasa sobre copia temporal de Dhaoz.otbm (1,045,077 tiles), con save/reopen y metadata verificados. | Ninguno dentro de este row. |
| P0 | Remove Corpses / Remove Unreachable de `main_menubar.cpp` y su dueño de mapa | **Cerrado** | `MapOperations.RemoveCorpses` compila la pertenencia oficial desde `tilesets.xml` y refleja `Materials::isInTileset` + `!Item::isComplex`, recorriendo ground/items directos sin entrar en contenedores. `MapOperations.RemoveUnreachable` refleja la ventana `x±10/y±8` y el rango de pisos de `OnMapRemoveUnreachable`. Ambos comandos usan confirmación, progreso, limpieza de selección/historial, `Map::doChange` equivalente y predicado local `has_map && !is_live`. Los validadores Release cubren fixtures semánticos y el OTBM autorizado; Remove Corpses además pasa roundtrip y elimina 244 items en 1,045,077 tiles. | Ninguna dentro de este row. |
| P0 | `live_*.cpp`, `live_packets.h`, `live_action.cpp`, `filehandle.cpp` | **Cerrado (Live Mapping)** | `Share/RmeLiveProtocol.cs` implementa el framing de 4 bytes, handshake/version gate, `CHANGE_CLIENT_VERSION`, `READY_CLIENT`, índices 4x4, máscaras de pisos, stream OTBM FE/FF/FD, `CHANGE_LIST`, ownership por bit flag, broadcasts sólo a nodos visibles, cursor/chat/operaciones y cliente remoto undoable. `MainForm` conecta `LIVE_START`, `LIVE_JOIN` y `LIVE_CLOSE` con enablement RME (`has_map && !is_live`, `loaded && !is_live`, `is_live`), host/join, pestañas Live, `ActionQueue`, viewport y `RmeLiveSessionLogForm` con log/chat/cierre. `--validate-live-mapping` y `--validate-live-mapping-ui` pasan la ruta activa, incluido cierre y limpieza. | Ninguna dentro de este row. |
| P1 | Reload Data Files (`MainMenuBar::OnReloadDataFiles` → `GUI::LoadVersion(..., true)`) | **Cerrado (Reload Data Files)** | LegacyX carga y valida antes del commit `items.otb/items.xml`, `Tibia.dat`, `materials.xml/tilesets.xml`; conserva el owner `OtItems` de mapas abiertos, reconstruye brushes/paletas, baja D3D11 a GDI durante el recambio, fuerza el reindexado SPR y refresca todas las pestañas. `--validate-reload-data` pasa sobre la ruta activa con una pestaña abierta. | Prueba manual prolongada con archivos modificados durante una sesión. |
| P1 | Recent Files | **N/A RME** | `MAKE_ACTION(RECENT_FILES, ...)` está comentado en `main_menubar.cpp`; RME conserva sólo el backend de persistencia sin comando activo. | No inventar un comando que la fuente no registra. |
| P1 | Automagic (`MainMenuBar::OnToggleAutomagic`) | **Cerrado** | `automagicMenuItem` es un checkbox persistente. El owner local actualiza `AutoBorderize`/`BorderIsGround`, refleja `USE_AUTOMAGIC`/`BORDER_IS_GROUND`, publica `Automagic enabled/disabled.` y enruta el acelerador normal `A`, según `main_menubar.cpp:95,439,1168-1177` y la tabla de aceleradores. `--validate-automagic` pasa. | Ninguna dentro de este row. |
| P1 | Prioridades, alpha, hangables y líquidos (`map_drawer.cpp::BlitItem`) | **Cerrado** | `MapRenderer` refleja el contrato fuente para ground separado, `AlwaysOnTop`/stack order, elevación acumulada, subtipo líquido, patrón de hangable y transparencia selectiva; `--validate-render` pasa con DAT/SPR 10.98 reales y reporta los casos focales. | Comparativa visual adicional por backend queda en la fila de overlays/DPI. |
| P1 | Overlays visuales, DPI y multimonitor | Implementado, no certificado completamente | La ruta funcional existe, pero la evidencia restante es comparativa de salida y geometría entre overlays, backend, escala DPI, zoom y monitor. | Fixtures deterministas por backend/DPI/zoom/piso y comparación de salida. |
| P1 | Propiedades/context menu y signs/books | Implementado, no certificado completamente | Falta cobertura por familia de objeto y predicados de habilitación. | Fixtures de cada familia y prueba WinForms de la ruta real. |
| P1 | OTBM/XML fuera del conjunto v1 certificado | Parcialmente cubierto | El proyecto declara extensiones de contenedor y corpus histórico adicionales como pendientes; no deben marcarse incompatibles sin especificación RME exacta. | Inventario atributo/nodo por versión, casos fuente y roundtrip por muestra autorizada. |

## Fuera del denominador de paridad RME

Planner, proveedores de IA, AreaGen, Ingame Simulation, Vivid y mejoras de
colaboración que exceden `source/` son trabajo sucesor de LegacyX. Se validan por
sus propios contratos, pero no pueden usarse para afirmar ni bloquear la paridad
clásica con RME.

## Orden del loop

1. Global Map Operations: cada operación en una iteración independiente.
2. Live Mapping: handshake → nodos → acciones → presencia → recuperación.
3. Certificación renderer/UI por fixture, sin relajar la cobertura declarada.
4. Inventario de atributos/nodos OTBM/XML de versiones soportadas.
5. Renderer/UI por fixture; Recent Files no agrega trabajo activo porque RME no registra su comando; Automagic ya está certificado.

Cada iteración debe registrar: `scope -> evidence -> gap -> patch -> focused test -> executable test -> remaining gaps`.

## Observación del baseline 2026-08-10

`dotnet build SharpMapTracker/SharpMapTracker.csproj -c Release --no-restore`
terminó con 0 errores y 0 advertencias. `--validate-global-operations` e
`--validate-input-interactions` pasaron, pero el primero sólo prueba búsqueda,
reemplazo, duplicados y eliminación por selección: no certifica comandos globales.
Las ejecuciones concurrentes de validadores que cargan el cliente compitieron por
`Release-Latest/data/1098/items.otb`; además, `--validate-otbm-v1` no terminó al
ejecutarse aislado durante la ventana de observación. Es un defecto abierto del
harness/arranque de validación, no evidencia de una regresión OTBM. El loop los
ejecuta en serie y exige diagnosticar ese arranque antes de usarlo como prueba de
paridad de parser.
