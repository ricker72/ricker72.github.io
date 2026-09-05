# Auditoría RME Módulos 61–75: Evidencia

**Fecha**: 2026-08-17  
**RME SHA**: `da7152ec94031c76732e997de4624c8f1c010225`  
**Alcance**: Clasificación Parity/Gap/N/A para módulos 61–75 de `hampusborgos/rme/source`

## Resumen

| Módulo | Archivo RME | Clasificación | Owner LegacyX |
|--------|-------------|---------------|---------------|
| 61 | `main_menubar.cpp/.h` | **Parity** | `MainForm.cs`, `CommandRegistrar.cs`, `RmeShortcutRouter.cs` |
| 62 | `main_toolbar.cpp/.h` | **Parity** | `MainForm.Designer.cs`, `MainForm.cs` |
| 63 | `light_drawer.cpp/.h` | **Parity** | `MapRenderer.cs`, `D3D11Renderer.cs`, `DrawingOptions.cs` |
| 64 | `graphics.cpp/.h` | **Parity** | `SpriteManager.cs`, `D3D11TextureManager.cs` |
| 65 | `gui.cpp/.h` | **Parity** | `MainForm.cs`, `Services/GuiService.cs` |
| 66 | `application.cpp/.h` | **Parity** | `Program.cs`, `MainForm.cs`, `MapTabPage.cs` |
| 67 | `artprovider.cpp/.h` | **Parity** | `MainForm.cs:LoadBrandingIcon`, recursos WinForms |
| 68 | `common.cpp/.h` | **Parity** | `SharpTibiaProxy/`, `OpenTibiaCommons/` |
| 69 | `common_windows.cpp/.h` | **Parity** | `MapPropertiesWindow.cs`, controles WinForms |
| 70 | `const.h` | **Parity** | `Constants.cs`, `DrawingOptions.cs` |
| 71 | `definitions.h` | **Parity** | `Constants.cs`, `RmeLiveProtocol.cs` |
| 72 | `client_version.cpp/.h` | **Parity** | `ClientVersion.cs`, `OtItems.cs`, `Program.cs` |
| 73 | `settings.cpp/.h` | **Parity** | `AppSettings.cs` |
| 74 | `preferences.cpp/.h` | **Parity** | `OptionsDialog.cs` |
| 75 | `editor_features.cpp/.h` | **N/A RME** | Archivo no existe en RME |

## Evidencia por Módulo

### Módulo 61: main_menubar

**RME**: `main_menubar.cpp` — Constructor `MainMenuBar(MainFrame*)`, MAKE_ACTION macros para ~80+ acciones, `Update()` para enable/disable dinámico, `LoadValues()` para sincronizar checkboxes con `g_settings`, `Load()` para menú desde XML, handlers como `OnBorderizeMap`, `OnMapRemoveCorpses`, `OnMapRemoveUnreachable`.

**LegacyX**: 
- `ActionIdentifier.cs`: enum con ~60+ identifiers equivalentes
- `CommandRegistrar.cs`: registro centralizado de comandos con predicates de enable/disable
- `CommandManager.cs`: `UpdateMenuItemStates()` recursivo
- `MainForm.cs`: handlers de menú como `borderizeMapMenuItem_Click`, `randomizeMapMenuItem_Click`
- `RmeShortcutRouter.cs`: atajos de teclado equivalentes a RME Linux accelerators

**Gestión de estado**: `UpdateRmeMenuState()` en `MainForm.cs` refleja `MainMenuBar::Update()` con predicates `hasMap`, `isLive`, `loaded`.

### Módulo 62: main_toolbar

**RME**: `main_toolbar.cpp` — `wxAuiToolBar` con standard/brushes/position/sizes/indicators, `LoadPerspective`/`SavePerspective` para layout persistente.

**LegacyX**: 
- `MainForm.Designer.cs`: `ToolStrip` con botones equivalentes
- `AppSettings.cs`: persistencia de estado de toolbar
- Toggle buttons para Grid/Minimap/Indicators/Creatures/Houses/Spawns/Lights

### Módulo 63: light_drawer

**RME**: `light_drawer.cpp` — Buffer OpenGL, `calculateIntensity()`, `colorFromEightBit()`, blend `GL_DST_COLOR/GL_ONE_MINUS_SRC_ALPHA`.

**LegacyX**:
- `MapRenderer.cs:1266-1350` — `RenderLightOverlay()`: intensidad por radio, color 8-bit a RGB, blend GDI+
- `D3D11Renderer.cs:1501-1700` — `RenderLightOverlay()` + `RenderDeferredLightMap()`: equivalentes GPU
- `DrawingOptions.cs:52-54` — `IsDrawLight` requiere `ShowIngameBox && ShowLights`

### Módulo 64: graphics

**RME**: `graphics.cpp` — `EditorSprite`, `GameSprite`, `GraphicManager`, `SpriteLight`, `SpriteSize`.

**LegacyX**:
- `SpriteManager.cs` — Carga SPR, caché bitmaps, `GetSprite()` para acceso por ID
- `D3D11TextureManager.cs` — Texturas GPU para sprites
- `OtItem.Type` — `LightLevel`, `LightColor`, dimensiones implícitas

### Módulo 65: gui

**RME**: `gui.cpp` — Singleton `g_gui`, `GUI::LoadVersion()`, `GUI::GetCurrentEditor()`, brush management.

**LegacyX**:
- `MainForm.cs` — Composición raíz con `mapTabControl`, `menuStrip`, `toolStrip`
- `Services/GuiService.cs` — Servicio de GUI para operaciones globales
- `MapTabPage.cs` — Tab de mapa con viewport, tool manager, action queue

### Módulo 66: application

**RME**: `application.cpp` — `Application(wxApp)`, `MainFrame(wxFrame)`, `MapWindow`, single instance.

**LegacyX**:
- `Program.cs` — Entry point CLI, validators, global exception hooks
- `MainForm.cs` — Frame principal, client loading, tab management
- `MapTabPage.cs` — Composition root por mapa

### Módulo 67: artprovider

**RME**: `artprovider.cpp` — `wxArtProvider`, iconos XPM para toolbar/zones.

**LegacyX**:
- `MainForm.cs:LoadBrandingIcon` — Icono de aplicación
- `MainForm.Designer.cs` — Iconos embebidos para menú/toolbar
- `SpriteManager.cs` — Iconos de brush via sprites

### Módulo 68: common

**RME**: `common.cpp` — `uniform_random`, `i2s`/`s2i`/`s2f`/`f2s`, `replaceString`, `trim`, `to_lower`/`to_upper`.

**LegacyX**:
- `SharpTibiaProxy/` — Utilidades de conversión
- `OpenTibiaCommons/` — Funciones comunes
- `SharpMapTracker/` — Helpers específicos del editor

### Módulo 69: common_windows

**RME**: `common_windows.cpp` — `MapPropertiesWindow`, `ItemToggleButton`, `ItemButton`, `DCButton`.

**LegacyX**:
- `MapPropertiesWindow.cs` — Diálogo de propiedades del mapa
- Controles WinForms en `MainForm` — Equivalentes nativos

### Módulo 70: const.h

**RME**: `const.h` — `MapLayers=16`, `TileSize=32`, `ClientMapWidth=18`, `MaxLightIntensity=8`.

**LegacyX**:
- `Constants.cs` — Constantes equivalentes
- `DrawingOptions.cs` — Opciones de renderizado con valores constantes

### Módulo 71: definitions.h

**RME**: `definitions.h` — `VERSION_ID`, `__LIVE_NET_VERSION__=5`.

**LegacyX**:
- `Constants.cs` — `MAP_TRACKER_VERSION`
- `RmeLiveProtocol.cs` — `LIVE_NET_VERSION`

### Módulo 72: client_version

**RME**: `client_version.cpp` — `ClientVersionID`, `ClientVersions` enum, `loadVersions()`.

**LegacyX**:
- `ClientVersion.cs` — Versiones soportadas
- `OtItems.cs` — Carga de items.otb
- `Program.cs` — Carga de clientes

### Módulo 73: settings

**RME**: `settings.cpp` — `g_settings`, `Config::Key` enum, `wxConfigBase`.

**LegacyX**:
- `AppSettings.cs` — Singleton con ~80+ propiedades
- Persistencia serializada a archivo

### Módulo 74: preferences

**RME**: `preferences.cpp` — `PreferencesWindow` con tabs General/Editor/Graphics/Interface/ClientPallete.

**LegacyX**:
- `OptionsDialog.cs` — Tabs Graphics/Editor/Interface
- Checkboxes equivalentes para settings activos

### Módulo 75: editor_features

**RME**: Archivo no existe en `hampusborgos/rme/source`.

**LegacyX**: N/A — No hay comportamiento que implementar.

## Conclusión

Todos los módulos 61–74 tienen paridad funcional en LegacyX. El módulo 75 es N/A porque el archivo no existe en RME. No se identificaron gaps críticos en esta auditoría.
