# Fase 2.1 — Auditoría AutoBorder: LegacyX Editor vs Remere's Map Editor

> Estado al 2026-08-03: auditoría histórica cerrada. D1–D12 fueron corregidas o
> clasificadas según la semántica ejecutable del commit RME
> `da7152ec94031c76732e997de4624c8f1c010225`. La evidencia reproducible vigente
> está en `04-brush-engine-certification.md` y `--validate-brush-engine`.

> **Auditoría histórica.** El estado vigente está en [03-current-parity-matrix.md](03-current-parity-matrix.md). Varias diferencias fueron implementadas después de esta auditoría.

- **Fecha**: 2026-08-01
- **Tipo**: auditoría solo lectura (no se escribió código, no se compiló)
- **Fase**: 2.1 de la ruta de paridad (sucesor del Plan 01 / antecedente del Plan 02)
- **Objetivo**: equivalencia funcional del flujo completo XML → AutoBorder → GroundBrush → clusters → border types → tile → items → render, contra la fuente autoritativa de RME.

---

## 1. Autoridad y alcance

### Fuente autoritativa RME

- Repositorio: `https://github.com/hampusborgos/rme`
- Rama/commit: `master` — SHA `da7152ec94031c76732e997de4624c8f1c010225` (2024-05-05)
- Snapshot plano local de inspección: `C:\Users\samatha\AppData\Local\Temp\opencode\rme-reference\`
- Archivos RME inspeccionados:
  - `source/ground_brush.cpp` (load L179-529, getBrushTo L573-639, doBorders L641-1007)
  - `source/ground_brush.h`
  - `source/brush.cpp` (friendOf L231-245)
  - `source/brush.h` (AutoBorder L298-313)
  - `source/brush_tables.cpp` (border_types L28-472)
  - `source/tile.cpp` (borderize/addBorderItem/cleanBorders L432-464)
  - `source/wall_brush.cpp` (doWalls L363-598)

### Fuente local LegacyX

- Raíz: `C:\Users\samatha\OneDrive\Desktop\Editor Alpha\sharpmaptracker-master`
- Archivos C# inspeccionados:
  - `SharpMapTracker/Brushes/OfficialMaterials.cs` (loader, AutoBorderEngine, brushes)
  - `SharpMapTracker/Brushes/TileBrushOps.cs` (fachadas Borderize/Wallize)
  - `SharpMapTracker/Brushes/BrushRegistry.cs` (LoadBorder stub)
  - `OpenTibiaCommons/Domain/OtTile.cs` (InsertItem, AddBorderItem, CleanBorders)
  - `OpenTibiaCommons/Domain/OtItemType.cs`
  - `OpenTibiaCommons/Domain/OtItems.cs`
- Datos certificados (solo lectura): `data/1098/` (grounds.xml y compañía)

### Regla

- Ninguna otra fuente externa de paridad fue utilizada (prohibidos forks, Canary, OTClient, TFS, wikis, memoria de modelo).

---

## 2. Mapa del flujo (pipeline)

```
materials.xml / grounds.xml
  └─ OfficialMaterials.OfficialMaterialLoader.Load / OfficialGroundBrush.Create
     ── parsea item, z-order, optional, border, friend, solo_optional
        └─ AutoBorderDef (Tiles[13], Group)      [LoadBorder / LoadInlineBorder]
           └─ + BorderMetadata, BorderItemIds, IsOptionalBorder (stamping)
        └─ GroundBorderRef (Outer, Target, BorderId, InlineBorder, SpecificCases)
           └─ ParseSpecific (conditions/actions)

pintar/borrar → OfficialGroundBrush.Draw/Undraw → AutoBorderEngine.Neighborhood
  └─ AutoBorderEngine.Borderize(map, tile)          (espejo Tile::borderize → GroundBrush::doBorders)
       1. quita ítems de borde existentes            (OfficialMaterials.cs:553-555)
       2. BrushFor(tile) → brush de suelo actual     (si nulo → return)
       3. barrido 8 vecinos NW,N,NE,W,E,SW,S,SE + máscara de bits
       4. puerta de vecino + friendOf / only_mountain
       5. clúster opcional (montaña, z=int.MaxValue) / FindRule → clústeres (merge por border, z=max)
       6. ordenar por z y emitir: BorderTypes[256] → 4 bytes edge → AddEdge → tile.AddItem
       7. ApplySpecificCases (match_border/item/group → replace_border/item, delete_borders)
  └─ OtTile.InsertItem  (apilado: Ground / GroundEquivalent→Insert(0) / AlwaysOnTopOrder)
     └─ OtTile.AddBorderItem / OtTile.CleanBorders   → APIs espejo de tile.cpp:432-464,
        PERO el motor no las invoca (usa AddItem)
  └─ render: sprite del ítem en su posición dentro del stack
```

---

## 3. Estado por paso del algoritmo

| # | Paso del algoritmo | Estado | Archivo : método (responsabilidad) |
|---|---|---|---|
| 1 | Parse `<border id>` / `<border ground_equivalent>` inline | Existe | `OfficialMaterials.cs:215-268` `LoadBorder` / `LoadInlineBorder` |
| 2 | Parse `<optional id>` (montaña/grava) | Existe | `OfficialMaterials.cs:367-369` (solo atributo `id`) |
| 3 | Parse `<optional ground_equivalent>` inline | **No existe** (latente; datos 10.98 no lo usan) | RME `ground_brush.cpp:208-226` |
| 4 | `Tiles[13]`, `group`, stamping `isBorder`/`isOptionalBorder` | Existe | `OfficialMaterials.cs:219-232, 258-265`; `OtItemType.cs:107` |
| 5 | Carga de brush (item, z-order, border, friend, solo_optional) | Parcial | `OfficialMaterials.cs:350-407` — faltan `friend name="all"`, `enemy`, `randomize` |
| 6 | Extracción de 8 vecinos + máscara de bits | Existe | `AutoBorderEngine.Borderize` + `Offsets` (`OfficialMaterials.cs:516-519, 562-579`) |
| 7 | **Puerta de vecino** | **Parcial / incorrecto** | `OfficialMaterials.cs:575` vs RME `ground_brush.cpp:730` |
| 8 | friendOf / only_mountain | Parcial | `OfficialMaterials.cs:566-568, 735-736` — falta comodín `"all"` |
| 9 | Clúster montaña (z = 0x7FFFFFFF, solo_optional) | Existe | `OfficialMaterials.cs:581-586` |
| 10 | getBrushTo → FindRule (4 ramas + zilch inner) | Existe | `OfficialMaterials.cs:684-726` |
| 11 | Zilch outer en tile sin suelo (`current == null`) | **No existe** (bloqueado) | `OfficialMaterials.cs:557` (early return); RME `ground_brush.cpp:835-877` |
| 12 | Merge de clústeres (mismo border, mask OR, z = max) | Existe | `AddCluster` `OfficialMaterials.cs:609-625` |
| 13 | Orden de emisión por z + apilado | **Parcial / invertido** | `OfficialMaterials.cs:602` + `OtTile.cs:759-768` |
| 14 | `border_types[256]` + decode de 4 bytes | Existe (tabla idéntica) | `OfficialMaterials.cs:522-540, 627-636` vs `brush_tables.cpp:28-472` |
| 15 | `addBorderItem` (insert al principio del stack) | Existe pero **no usado** | `OtTile.cs:361-366`; el motor usa `AddItem` |
| 16 | Descomposición diagonal SW/SE | **Incorrecto** | `OfficialMaterials.cs:677-681` vs RME `ground_brush.cpp:914-920` |
| 17 | Specific cases (match_* / replace_* / delete_borders) | Parcial | `OfficialMaterials.cs:410-453, 638-667` — diferencias menores |
| 18 | Limpieza de bordes antes de emitir | Existe | `OfficialMaterials.cs:553-555` (timing distinto, inofensivo) |
| 19 | `BrushRegistry.LoadBorder` | **No existe (stub muerto)** | `BrushRegistry.cs:295` — superado por el loader oficial |

---

## 4. Diferencias funcionales, ordenadas por prioridad

### P1 — Correctitud visual, ejercitadas por los datos 10.98

**D1. Puerta de vecino con operandos intercambiados y definiciones infladas**

- RME `ground_brush.cpp:730`:
  ```cpp
  if(other->hasOuterBorder() || borderBrush->hasInnerBorder()) { ... }
  ```
- LegacyX `OfficialMaterials.cs:575`:
  ```csharp
  if (!current.HasOuterBorder && !other.HasInnerBorder) continue;
  ```
- Además, las definiciones difieren:
  - RME `has_outer_border`/`has_inner_border` se activan SOLO con refs no-zilch (`ground_brush.cpp:317-329`): excluyen `to="none"` y excluyen el `<optional>`.
  - LegacyX `HasOuterBorder` incluye `OptionalBorderId > 0` (`OfficialMaterials.cs:731-733`) y `HasInnerBorder` incluye refs zilch (`OfficialMaterials.cs:728-729`).
- **Impacto con datos**: `sandstone` (z=8600, solo-inner, borde wildcard inline) pierde su borde contra los 36 brushes sin refs de borde (cobblestone, stone floor, void, dry earth, …). RME sí lo dibuja (el borde wildcard inner `to=0xFFFFFFFF` casa con cualquier vecino). `lava` (solo-inner con refs dirigidos a `cave`/`mountain top ground`) se ve menos afectado por no tener wildcard.
- **Caso RME que LegacyX omite**: A solo-inner (p. ej. sandstone) contra B sin refs → RME procesa (A.hasInnerBorder) y dibuja; LegacyX salta.

**D2. Comodín `<friend name="all">` no implementado**

- RME `ground_brush.cpp:476-477`: `name == "all"` → `friends.push_back(0xFFFFFFFF)`.
- RME `brush.cpp:238-240`: `friendOf` devuelve `!hate_friends` (true) si el otro casa con `0xFFFFFFFF`.
- En `doBorders` (`ground_brush.cpp:732-737`): si `other->friendOf(borderBrush) || borderBrush->friendOf(other)` → `only_mountain = true` (y si el otro no tiene optional → `continue`, sin borde).
- LegacyX `AreFriends` (`OfficialMaterials.cs:735-736`) compara nombres literales; `"all"` nunca casa con el nombre de un brush → no aplica el only_mountain.
- **Impacto con datos**: **15 brushes** declaran `<friend name="all"/>` (stone/tile floors: dark tiled sandstone, dark sandstone, gray stone tiles pressed/depressed, small tiled gray stone, drawbridge, dark/light tiled stone floor, tiled sandstone floor ±pressed/depressed, orange tiled floor, ice stone floor, dark wooden floor (seabed), dark wooden floor). En RME estas superficies **no reciben** bordes de brushes wildcard-inner (sandstone, snowy mountain, icy mountain); LegacyX **sí** dibuja esos bordes.

### P2 — Apilado y render

**D3. Orden de emisión multi-clúster invertido**

- RME: ordena clústeres asc por z (`ground_brush.cpp:882`) y consume desde `back()` (mayor z primero, L885-886); cada `addBorderItem` inserta en `items.begin()` (`tile.cpp:437`) → el clúster de mayor z queda **arriba**.
- LegacyX: emite `OrderByDescending(ZOrder)` (`OfficialMaterials.cs:602`) y apila por append estable dentro del mismo `AlwaysOnTopOrder` (`OtTile.cs:759-768`) → el clúster de mayor z queda **abajo**.
- **Impacto**: cualquier tile con 2+ clústeres de distinto z (p. ej. grass z=3500 contra ice y void a la vez) dibuja el sprite de bordes equivocado encima.

**D4. Bordes ground-equivalent (montaña/grava) anclados al fondo absoluto**

- RME: clúster de montaña con z = 0x7FFFFFFF (por encima de todos los bordes) (`ground_brush.cpp:753, 869`).
- LegacyX: `OtTile.InsertItem` rama `GroundEquivalent` hace `Items.Insert(0, item)` (`OtTile.cs:754`) → el ítem de montaña queda en el índice 0, debajo de todo borde normal.
- **Impacto**: la grava de montaña se renderiza **bajo** el borde normal (RME la dibuja encima). Visible siempre que un tile tenga borde normal + grava.

**D5. Descomposición diagonal SW/SE invertida**

- RME `ground_brush.cpp:914-920`:
  - SW → `tiles[SOUTH]` + `tiles[WEST]`
  - SE → `tiles[SOUTH]` + `tiles[EAST]`
- LegacyX `AddEdge` `OfficialMaterials.cs:677-681`:
  - edge 11 (dsw) → `Tiles[2]`(EAST) + `Tiles[3]`(SOUTH)  ← equivale al patrón SE de RME
  - edge 12 (dse) → `Tiles[4]`(WEST) + `Tiles[3]`(SOUTH) ← equivale al patrón SW de RME
- **Impacto**: solo se activa cuando el borde no define su tile diagonal (`Tiles[11]`/`Tiles[12] == 0`).

### P3 — Latente / límites de mapa

**D6. `current == null` bloqueado (tile sin suelo)**
- `OfficialMaterials.cs:557` hace `return` si no hay brush de suelo en el tile.
- RME `ground_brush.cpp:835-877` procesa este caso: zilch-outer (`getBrushTo(nullptr, other)`, z = `other->getZ()`), clúster de montaña sobre zilch, y `tile->setOptionalBorder(false)` cuando no procede.

**D7. `to="all"` no manejado**
- RME `ground_brush.cpp:286-287`: `to="all"` → `0xFFFFFFFF` (casa con cualquier vecino). LegacyX lo trataría como nombre literal. **0 usos en datos 10.98** (latente).

**D8. `<optional ground_equivalent>` inline no parseado**
- RME `ground_brush.cpp:208-226` crea un `AutoBorder` inline desde `ground_equivalent`. LegacyX solo lee `optional.id` (`OfficialMaterials.cs:368`). Datos 10.98 usan solo `<optional id>` (4) → latente.

**D9. `super` / `enemy` sin hueco de paridad**
- RME parsea `super` (`ground_brush.cpp:302-304`) pero **nunca** lo consume en `doBorders` (muerto en este commit). `enemyOf` se parsea (`ground_brush.cpp:488-499`) pero nunca se usa.
- Por tanto LegacyX los ignora sin divergencia. Datos: `super="true"` (2, sandstone), `<enemy name="all"/>` (1, stairs). El `<enemy name="all">` de stairs produce `friendOf` = false para todos → sin efecto en el flujo de bordes.

### P4 — Menor

**D10. Alcance/contaje de matching en specific cases**
- RME escanea solo ítems de borde iniciales (`ground_brush.cpp:941-943`) y exige `matches == items_to_match.size()` (con quirk cuando `item->getID() == group`).
- LegacyX escanea todo `tile.Items` y usa `All(conditions)` (`OfficialMaterials.cs:642-648`).
- En la práctica equivalente para 10.98 (0 `<specific>` multi-acción, 0 refs dirigidos a floors friend-all).

**D11. Replace en specific cases no es in-place**
- RME `item->setID(with_id)` in-place (`ground_brush.cpp:998`) preserva posición y flags. LegacyX `RemoveItem` + `AddItem` (`OfficialMaterials.cs:660-663`) reentra el ítem por `AlwaysOnTopOrder`.

**D12. `randomize` de ground brush no se parsea**
- RME `ground_brush.cpp:168-169` → `isReRandomizable()`. **0 usos en datos 10.98** (latente).

---

## 5. Verificaciones equivalentes confirmadas (sin cambio requerido)

- `BorderTypes[256]` de LegacyX es idéntico por índice a `GroundBrush::border_types` de RME (`brush_tables.cpp:28-472`).
- Orden de vecinos (NW,N,NE,W,E,SW,S,SE) y mapeo de bits de máscara idénticos.
- Semántica `to`: `"none"`→0 (zilch), `"all"`/sin `to`→0xFFFFFFFF (`ground_brush.cpp:284-300`); `getBrushTo` iguala `to == id || to == 0xFFFFFFFF` (inner) y `to == 0` (zilch) — mirror en `FindRule`/`FindBorder`.
- Zilch inner (borde contra vacío/frontera, z=5000) implementado y con flag correcto (`to="none"` sin wildcard).
- Clúster de montaña: `other.OptionalBorderId > 0 && tile.HasOptionalBorder`; `solo_optional` → only_mountain (parseado y usado).
- friendOf por nombre (no-wildcard) y flujo only_mountain correctos.
- Merge de clústeres (mismo `AutoBorderDef`, mask OR, z = max) correcto.
- Decode de `border_types` en 4 bytes y fallback diagonal NW/NE correctos (SW/SE no, ver D5).
- Timing de specifics: aplicados después de la emisión, una vez por regla usada (RME `ground_brush.cpp:927`).
- `OtTile.AddBorderItem`/`CleanBorders` son espejos correctos de `tile.cpp:432-464` (pero no los usa el motor, ver D3/D4).
- El flag `OptionalBorder` de tile (estadística `OtTile.cs:171-181`) y su seteo al insertar ítems `IsOptionalBorder` (L730-731) están en su lugar.

---

## 6. Validación ejecutada (read-only)

1. Comparación línea a línea `AutoBorderEngine.Borderize` (`OfficialMaterials.cs:549-607`) vs `GroundBrush::doBorders` (`ground_brush.cpp:641-1007`).
2. Comparación `FindRule`/`FindBorder` (`OfficialMaterials.cs:684-726`) vs `getBrushTo` (`ground_brush.cpp:573-639`).
3. Verificación de datos 10.98 (conteos en `data/1098/grounds.xml`):
   - 121 brushes de suelo; 31 inner+outer, 49 outer-only, 2 inner-only (lava, sandstone), 36 sin refs, 3 optional-only (wooden ladder trapdoor, wooden ladder hole, wooden trapdoor).
   - 40 zilch-outer (`to="none"` outer), 28 zilch-inner.
   - 117 `<specific>`; 221 `match_border`, 9 `match_item`, 8 `match_group`, 96 `replace_border`, 9 `replace_item`, 12 `delete_borders`; 0 multi-acción.
   - 15 `<friend name="all"/>`; 4 `<optional id>`; 3 bordes inline `ground_equivalent` (sandstone); 2 `solo_optional`; 2 `super`; 1 `<enemy>`; 0 `randomize`; 0 `to="all"`.
4. Confirmado por grep que `OtTile.AddBorderItem`/`CleanBorders` no tienen callers en el proyecto (el motor usa `AddItem`).

---

## 7. Pendiente (fuera del alcance read-only de esta fase)

- A/B de render real para confirmar D3/D4/D5 en tile: grass+ice, grass+void, sandstone+stone floor, montaña con grava.
- Implementación priorizada (ver §8) con validación `dotnet build SharpMapTracker/SharpMapTracker.csproj -c Release --no-restore` y los validadores enfocados del Plan 01.

---

## 8. Qué falta para equivalencia funcional (orden de trabajo propuesto)

1. **D1** — Corregir la puerta de vecino (`OfficialMaterials.cs:575` + definiciones `HasOuterBorder`/`HasInnerBorder` L728-733) al predicado RME: procesar si `other` tiene ref outer no-zilch **o** `current` tiene ref inner no-zilch; excluir `<optional>` de `HasOuterBorder` y los refs `to="none"` de `HasInnerBorder`.
2. **D2** — Implementar el comodín `friend name="all"` en `AreFriends` (`OfficialMaterials.cs:735-736`).
3. **D3 + D4** — Revertir el apilado: emitir clústeres en orden **ascendente** de z (o insertar al frente del grupo de bordes) y usar `AddBorderItem` para los ítems ground-equivalent para que la montaña quede encima del borde normal.
4. **D5** — Corregir la descomposición SW/SE en `AddEdge` (`OfficialMaterials.cs:677-681`).
5. **D6** — Desbloquear el caso `current == null` (zilch-outer, montaña sobre zilch, `setOptionalBorder(false)`).
6. **D7/D8/D12** — (Latente) `to="all"`, `<optional ground_equivalent>` inline, `randomize`.
7. **D11** — (Opcional) replace in-place en specific cases.
8. **Limpiar** el stub muerto `BrushRegistry.LoadBorder` (`BrushRegistry.cs:295`) tras confirmar que el loader oficial lo reemplaza.

---

*Declaración de autoridad: la única fuente externa de paridad utilizada fue `hampusborgos/rme` (master, SHA `da7152ec94031c76732e997de4624c8f1c010225`, snapshot local en `C:\Users\samatha\AppData\Local\Temp\opencode\rme-reference`). No se usaron forks, Canary, OTClient, TFS, wikis, blogs ni memoria de modelo como evidencia de compatibilidad.*
