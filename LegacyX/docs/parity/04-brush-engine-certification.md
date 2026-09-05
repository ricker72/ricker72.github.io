# Certificación Brush Engine 10.98

Fecha: 2026-08-03  
Autoridad: `hampusborgos/rme/source`, commit `da7152ec94031c76732e997de4624c8f1c010225`.

## Fuentes contrastadas

- RME: `ground_brush.cpp`, `wall_brush.cpp`, `doodad_brush.cpp`, `brush.cpp`,
  `brush_tables.cpp` y `tile.cpp`.
- LegacyX: `Brushes/OfficialMaterials.cs`, `Brushes/BrushRegistry.cs`,
  `OpenTibiaCommons/Domain/OtTile.cs` y `Viewport/ActionSystem.cs`.
- Datos: `data/1098`, `items.otb`, `items.xml`, `Tibia.dat` y `Tibia.spr`.

## Contrato certificado

- Ground y AutoBorder reproducen el orden de los ocho vecinos, tabla de 256
  máscaras, reglas inner/outer/zilch/wildcard, `friend name="all"`, optional,
  `solo_optional`, z-order y fallback diagonal oficial.
- Los borders se insertan al inicio del stack mediante `AddBorderItem`; la
  limpieza se detiene ante el primer ítem no-border igual que `Tile::cleanBorders`.
- Specific cases examinan solo el prefijo de borders, exigen el conteo exacto y
  reemplazan en la misma posición del stack.
- Ground, Wall y Doodad restauran todos los tiles afectados si falla una mutación
  o postproceso. Composite Doodad y vecinos Wall se registran como una sola acción.
- Undo/redo restaura el stack completo. Save/reopen OTBM conserva el fingerprint.
- Los randomizers personalizados ponderan únicamente grounds 10.98 presentes en
  OTB. El modo compuesto exige ownership de `OfficialGroundBrush`, deriva sus
  AutoBorders oficiales y admite capas `OfficialDoodadBrush` mutuamente
  excluyentes cuya probabilidad total no supera 100 %. Un trazo completo sigue
  siendo una sola transacción y no cambia de piso.

## Conteos certificados del corpus

| Regla | Resultado |
|---|---:|
| `<specific>` compiladas | 117 |
| `<optional>` compiladas | 4 |
| `<alternate>` léxicas | 434 |
| Alternates comentadas/inactivas | 2 |
| Alternates XML activas | 432 |
| Alternates Doodad ejecutables | 430 |
| Alternates Wall ignoradas por RME | 2 |

Dos etiquetas pertenecen a contenido comentado y no forman parte del DOM XML.
Las dos declaraciones Wall activas tampoco se presentan como funcionales:
`WallBrush::load` no interpreta `<alternate>` en la fuente oficial. El validador
exige que las 434 queden contabilizadas y que ninguna desaparezca silenciosamente.

## Reproducción

```powershell
dotnet build SharpMapTracker\SharpMapTracker.csproj -c Release --no-restore
SharpMapTracker\bin\Release\net10.0-windows\LegacyXEditor.exe `
  --validate-brush-engine "C:\Users\samatha\OneDrive\Desktop\Editor Alpha\Tibia"
SharpMapTracker\bin\Release\net10.0-windows\LegacyXEditor.exe `
  --validate-custom-brush-palette "C:\Users\samatha\OneDrive\Desktop\Editor Alpha\Tibia"
```

Resultado certificado: compilación Release sin errores y
`BRUSH_ENGINE_VALIDATION=PASS`. El validador incluye GroundEquivalent, RAW
item-only, current-null, friend-all, specific/optional/alternate, Wall/door,
Doodad composite, transacciones, undo/redo y roundtrip OTBM.
