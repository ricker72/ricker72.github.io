# Certificación de roundtrip OTBM y XML 10.98

Fecha: 2026-08-03  
Autoridad: RME `hampusborgos/rme` commit `da7152ec94031c76732e997de4624c8f1c010225`.

## Contrato certificado

La ruta activa `OtMap.Load → OtMap.Save → OtMap.Load` conserva durante dos ciclos:

- versión y dimensiones OTBM, versión OTB, descripciones;
- posiciones, pisos 0–15, flags de tile y HouseId;
- ground y stack ordenado de items;
- atributos simples y complejos, incluidos texto, descripción, writer/date,
  action/unique ID, count/charges, duración/decay;
- destinos de teleport, IDs de door/depot y contenido recursivo de containers;
- towns, houses, exits, rent, town, guildhall y waypoints;
- centros/radios de spawn, monster/NPC, offsets, spawn time y direction;
- atributos y elementos XML desconocidos en roots, houses, spawns y creatures.

El nombre de los sidecars cambia de forma intencional durante Save As para seguir
el nombre base del OTBM. Esto no altera su semántica.

## Evidencia fuente

- RME: `source/iomap_otbm.cpp`, `source/editor.cpp`, `source/item.cpp`,
  `source/complexitem.cpp`.
- LegacyX: `OpenTibiaCommons/Domain/OtMap.cs`, `OtItem.cs`, `OtContainer.cs`,
  `OtTeleport.cs`, `OtDoor.cs`, `OtDepot.cs`; `SharpMapTracker/MapTabPage.cs`.

## Validación Release

Comando:

```powershell
dotnet SharpMapTracker/bin/Release/net10.0-windows/LegacyXEditor.dll `
  --validate-map-roundtrip <Tibia-10.98> <map.otbm>
```

Resultados:

- Dhaoz-1098: 1,045,077 tiles, 954 spawns, 6,753 criaturas — PASS.
- Krailos: 210,134 tiles, 568 spawns, 867 criaturas — PASS.
- compilación Release `--no-restore`: 0 errores, 0 advertencias — PASS.

Los OTBM y XML originales se usan solo como entrada. Toda escritura de prueba se
realiza en un directorio temporal y el validador conserva dicho directorio si falla.
