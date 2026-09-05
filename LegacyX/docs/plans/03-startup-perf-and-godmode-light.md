# Plan: Startup Performance + God Mode Light Limit

- **Fecha**: 2026-08-16
- **Estado**: Plan listo para implementación

---

## Tarea 1: Optimizar inicio de la aplicación

### Problema

Todo el bloque de splash (Program.cs L1199-1253) carga datos pesados **síncronamente en el UI thread**:

1. `items.otb` binary parse + `items.xml` XML parse (L1207-1218)
2. Materials XML parse **3 veces** por archivo (OfficialMaterials.cs L132-195)
3. Brush icon PNG loading (BrushRegistry.cs L168-190)
4. Creature data directory scan + XML parse (CreatureAppearanceCatalog.cs L69-127)

### Cambios

#### 1a. Fundir triple parse de materials XML en un solo pase

**Archivo**: `SharpMapTracker/Brushes/OfficialMaterials.cs` — método `Load()` (L105-219)

**Antes** (3 passes por cada archivo):
- Pass 1 (L132-151): `File.ReadAllText()` + `Regex.Matches()` + `XDocument.Load()` para conteo de specifics/optional/alternate
- Pass 2 (L152-157): `XDocument.Load()` para borders
- Pass 3 (L159-195): `XDocument.Load(LoadOptions.SetLineInfo)` para brush creation

**Después** (1 solo pase):
- Cargar `XDocument.Load(LoadOptions.SetLineInfo)` una vez por archivo
- En un solo loop, extraer: metaitems, conteos (specifics/optional/alternate), borders, y brushes
- Eliminar los 2 passes anteriores
- Eliminar `File.ReadAllText()` + `Regex.Matches()` (reemplazado por LINQ sobre el XDocument ya cargado)

#### 1b. Mover carga de items.otb + items.xml a background thread

**Archivo**: `SharpMapTracker/Program.cs` — bloque splash (L1199-1253)

- Envolver `preloadedItems.Load(itemsOtbPath)` + `preloadedItems.LoadXml(itemsXmlPath)` en `Task.Run()`
- Mantener el splash visible con "Loading items..." mientras el Task corre
- La carga de materials puede empezar después en paralelo o secuencialmente en el mismo Task

#### 1c. Mover carga de brush icons a background thread

**Archivo**: `SharpMapTracker/Program.cs` — L1229-1236

- Envolver `BrushRegistry.Instance.LoadIcons(brushIconDir)` en `Task.Run()`
- Los iconos se cargan lazy (solo cuando el palette los necesita)

#### 1d. Mover carga de creature data a background thread

**Archivo**: `SharpMapTracker/Program.cs` — L1239-1249

- Envolver `CreatureAppearanceCatalog.Instance.LoadServerDataDirectory(creaturePath)` en `Task.Run()`
- Ya está en try-catch, así que no afecta el flujo

#### 1e. Eliminar llamada redundante a RuntimeDiagnostics.Initialize()

**Archivo**: `SharpMapTracker/Program.cs` — L1162

- Eliminar la segunda llamada (la primera es L42)

### Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `SharpMapTracker/Brushes/OfficialMaterials.cs` | Fundir 3 passes en 1 |
| `SharpMapTracker/Program.cs` | Mover carga a threads, eliminar línea redundante |

### Criterio de aceptación

- `dotnet build SharpMapTracker/SharpMapTracker.csproj -c Release --no-restore` → 0 errores
- La aplicación abre y el splash desaparece más rápido
- Los brushes, items, y creature data se cargan correctamente (verificar palette llena)

---

## Tarea 2: Limitar luz del God Mode y respetar área visible

### Problema

`GodModeSunlight` dibuja un glow radial alrededor del personaje:
- Radio de 3.5-7.5 tiles según hora del día
- Sin clipping al rango de tiles visibles (`startTX..endTX, startTY..endTY`)
- Sin clipping a los límites del viewport
- Alpha de 30-75/255, mucho más intenso de lo necesario

### Cambios

#### 2a. Reducir radio y alpha en los perfiles de luz

**Archivo**: `SharpMapTracker/Viewport/GodModeSunlight.cs`

| Hora | Radio antes | Radio después | Alpha antes | Alpha después |
|------|-------------|---------------|-------------|---------------|
| 05-07 (dawn) | 5.0 | 2.5 | 55 | 35 |
| 07-17 (day) | 6.5 | 3.0 | 70 | 45 |
| 17-19 (sunset) | 7.5 | 3.5 | 75 | 50 |
| 19-21 (dusk) | 4.5 | 2.0 | 45 | 30 |
| 21-05 (night) | 3.5 | 1.5 | 30 | 20 |

#### 2b. Agregar clipping al rango visible en D3D11

**Archivo**: `SharpMapTracker/Viewport/D3D11Renderer.cs` — `RenderGodModeSunlight` (L1336-1373)

- Agregar clipping: solo dibujar tiles que estén dentro de `visStartX..visEndX, visStartY..visEndY`
- Solo dibujar tiles que estén dentro del viewport pixel (0..viewWidth, 0..viewHeight)

```csharp
// Agregar después de WorldToScreen (L1358-1362):
int ps = camera.PixelSize;
if (x + ps < 0 || x > viewWidth || y + ps < 0 || y > viewHeight)
    continue;
```

#### 2c. Agregar clipping al rango visible en GDI+

**Archivo**: `SharpMapTracker/Viewport/MapRenderer.cs` — `RenderGodModeSunlight` (L1371-1403)

- La GDI+ versión dibuja un `PathGradientBrush` ellipse gigante sin clipping
- Agregar `g.SetClip(new Rectangle(0, 0, viewWidth, viewHeight))` antes de dibujar y `g.ResetClip()` después
- Esto recorta el ellipse a los límites del viewport

### Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `SharpMapTracker/Viewport/GodModeSunlight.cs` | Reducir radio/alpha |
| `SharpMapTracker/Viewport/D3D11Renderer.cs` | Agregar clipping de tiles |
| `SharpMapTracker/Viewport/MapRenderer.cs` | Agregar clipping de viewport |

### Criterio de aceptación

- `dotnet build SharpMapTracker/SharpMapTracker.csproj -c Release --no-restore` → 0 errores
- God Mode activado: la luz del personaje es más sutil y no se extiende más allá del viewport
- La luz se recorta correctamente a los bordes de la pantalla
- No hay regresión en la renderización normal de map lights

---

## Orden de ejecución

1. Tarea 1 (startup) — cambios en OfficialMaterials.cs y Program.cs
2. Tarea 2 (God Mode light) — cambios en GodModeSunlight.cs, D3D11Renderer.cs, MapRenderer.cs
3. Build Release + validación manual
