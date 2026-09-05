# Mandatory LegacyX Editor guardian

Before inspecting, planning, editing, testing, building, packaging, deleting, migrating, or otherwise modifying this repository, invoke and follow:

`.agents/skills/rme-source-only-guardian/SKILL.md`

Then invoke and follow the local architecture and debugging guide:

`.agents/skills/sharpmaptracker-architecture/SKILL.md`

For every custom, randomizer, weighted, composite, biome, extension-menu,
AutoBorder-layer, or Doodad-layer brush task, also invoke and follow:

`.agents/skills/legacyx-composite-brush-architect/SKILL.md`

This is a blocking gate for every AI agent.

For Remere's Map Editor parity, the only permitted external authority is:

`https://github.com/hampusborgos/rme/tree/master/source`

Do not use other RME forks, Canary, OTClient, TFS, OpenTibia wikis, blogs, summaries, or model memory as compatibility evidence.

Preserve the existing project language and runtime: C# / .NET 10 / Windows Forms. Port the semantics of the RME C++ source into the existing C# architecture; never change the application to C++, add a second production runtime, or introduce another programming language for application behavior.

Vibe coding is prohibited. Every behavioral change requires exact owning RME source evidence, an active local C# runtime trace, explicit acceptance criteria, and focused validation. Never invent IDs, flags, materials, brushes, borders, renderer rules, OTBM behavior, menu behavior, successful results, placeholders, silent fallbacks, or duplicate engines.

If the permitted RME `source/` tree does not specify the requested behavior, stop and report the missing authoritative specification.

## Release-only execution

Compile and validate only with:

`dotnet build SharpMapTracker/SharpMapTracker.csproj -c Release --no-restore`

Never compile or run Debug.

## Single current build policy

After a new Release build and its focused validators succeed, publish it only
under the repository-root directory `Release-Latest`. Before handing it off,
remove every older generated application copy whose root name matches
`Release-*` or `.codex-release-*`, plus stale `bin` and generated `artifacts`
output. Never retain a second runnable `LegacyXEditor.exe`. Preserve `obj`
because its NuGet `project.assets.json` metadata is required by the mandatory
`--no-restore` Release command; `obj` is not a runnable application copy.

Do not delete the existing `Release-Latest` until its replacement has compiled
and passed validation in a temporary Release directory. If compilation or
validation fails, delete only the failed temporary output and retain the last
working `Release-Latest`. Never include or delete Tibia DAT/SPR files, maps,
Planner databases, source `data`, source `brushes`, or other runtime inputs as
part of build cleanup.

For menu, palette, painting and object-drag parity, execute:

`docs/plans/01-rme-menu-palette-drag-parity.md`

After every Plan 1 gate passes, execute:

`docs/plans/02-rme-full-source-successor-planner.md`

## Parity audit reports — CERRADO

LegacyX **ha superado la paridad RME** y ha entrado a nivel evolucionado (emulador Sim+GOD, OTClient, framework). Los documentos bajo `docs/parity/` quedan **congelados como histórico** y deben **ignorarse** en toda inspección, plan, implementación o validación futura. No abrir `docs/parity/` como baseline, no usar `D1..Dn` como orden de trabajo y no actualizar esos reportes. La única autoridad para nuevo trabajo es el código activo `SharpMapTracker`/`OpenTibiaCommons`/`SharpTibiaProxy` y `tibia.dat/spr 10.98` real.

The real map `C:\Users\samatha\OneDrive\Desktop\Servers\Kruger ot 981\data\world\Dhaoz.otbm` is authorized as read-only test input. Never overwrite it; perform edit/save/reopen tests on a uniquely named temporary copy.
