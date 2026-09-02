# Lua-API — Notizen

Stand: PrusaSlicer **3.0.0-alpha11**. Die API ist experimentell; Breaking Changes sind
angekündigt.

Primärquellen — und zwar der Quellcode selbst, nicht die Prosa-Doku:

- [`doc/Plugin_API.md`](https://github.com/prusa3d/PrusaSlicer/blob/version_3.0.0-alpha11/doc/Plugin_API.md) — Einstieg, Manifest, Signierung
- [`src/.../Lua/ProjectApi.cpp`](https://github.com/prusa3d/PrusaSlicer/blob/version_3.0.0-alpha11/src/slic3r-shared/src/Slic3r/App/Lua/ProjectApi.cpp) — **die eigentliche Referenz**; die Registrierung trägt vollständige LuaLS-Annotationen
- [`src/.../Lua/PluginDialog.cpp`](https://github.com/prusa3d/PrusaSlicer/blob/version_3.0.0-alpha11/src/slic3r-shared/src/Slic3r/App/Lua/PluginDialog.cpp) — welche Parameter-Typen der Dialog kennt
- `resources/lua/com.prusa3d.slicer.calibration/` — Prusas eigene Plugins als Referenzimplementierung

## Plugin-Grundgerüst

Eine globale Tabelle `info` und eine globale Funktion `execute(opts)`. Weitere Lua-Dateien
im Bundle sind per `require('dateiname')` (ohne Endung) als Module einbindbar.

## Parameter-Typen

Genau vier, laut `PluginDialog.cpp`: `string`, `float`, `int`, `bool`.
Keine Enums, keine Listen, keine Min/Max-Grenzen, keine Tooltips.

> Korrektur: `doc/Plugin_API.md` nennt nur `float`, `int` und `bool`. `string` existiert
> aber und wird von Prusas eigenem Flow Tower benutzt.

## Geometrie

Alle Primitive sind prozedural — wir sind **nicht** auf mitgelieferte STLs angewiesen:

```
api.make_cube(width, height, depth)
api.make_sphere(radius, fa?)
api.make_cylinder(radius, height, fa?)
api.make_cone(radius, height, fa?)
api.make_frustum(radius, height, fa?)
api.make_frustum_dowel(radius, height, sector_count)
api.make_torus(r, t, ra?, ta?)
api.make_prism(width, length, height)
api.make_pyramid(base, height)
api.make_tetrahedron(size)
api.make_snap(radius, height, space_proportion?, bulge_proportion?)

api.load_stl(path)
api.emboss_svg(path, depth)
api.emboss_text{font=, text=, depth=, line_height=}

api.fonts() / api.get_default_font() / api.get_font(name)
```

`Mesh:bounds()` liefert eine BoundingBox mit `min_x/max_x/min_y/max_y/min_z/max_z`,
`Mesh:translate(x, y, z)` verschiebt.

## Objekte und Volumes

```lua
api.project:add_object{
    mesh = <Mesh>,
    translate = {x=, y=, z=},      -- optional
    rotate = {x=, y=, z=},         -- Grad, optional
    object_params = {...},         -- Einstellungen für das ganze Objekt
    other_volumes = { <VolumeDefinition>, ... }
}
```

Ein `VolumeDefinition` hat `mesh`, optional `translate`, `rotate`, `type` und `params`.
`VolumeType`: `Solid`, `Negative`, `Modifier`, `SupportBlocker`, `SupportEnforcer`,
`Invalid`. Ohne `type`, aber mit `params`, wird automatisch `Modifier` gesetzt.

Damit sind boolesche Abzüge (Negative) und ortsabhängige Einstellungen (Modifier)
verfügbar — deutlich mehr, als die Prosa-Doku vermuten lässt.

## Einstellungen

```lua
local bed = api.project:current_bed()
bed:print_presets():set(name, value)   -- und :value(name)
bed:printer_presets()
bed:tool_print_presets(tool_idx)
bed:material_presets(slot_idx)
bed:printer_config().tools[1]:nozzle_diameter()
```

## Custom G-Code pro Schicht

```lua
api.project:insert_layer_custom_gcode(bed, z_depth, gcode)
api.project:clear_layer_custom_steps(bed)
```

Das ist der Hebel für alles, was **Firmware-Zustand** ist: Temperatur (`M104`),
Lüfter (`M106`/`M107`). Prusas Temperature Tower nutzt genau das.

## Sandbox

Kein `os`, kein `io`, kein Netzwerk. Dateizugriff nur im eigenen Plugin-Verzeichnis.
`print()` existiert (Flow Tower benutzt es) — wohin die Ausgabe geht, ist ungeprüft.

## Offene Fragen

Diese Punkte konnten wir aus dem Quellcode **nicht** abschließend klären. Sie stehen
alle unter „muss am laufenden Slicer verifiziert werden":

1. **Rotations-Pivot.** Wird `rotate` um den lokalen Ursprung des Volumes angewendet,
   und vor `translate`? Unsere Beschriftungen in `labels.lua` nehmen das an. Prusas
   Temperature Tower benutzt zwar `rotate{x=90}`, aber mit handgetunten Magic Numbers,
   aus denen sich die Semantik nicht sicher ableiten lässt.
2. **Ursprung der Primitive.** `its_make_cube` erzeugt den Würfel von (0,0,0) aus, das
   passt zu `note_badge.lua`. Ob `make_cylinder` in XY zentriert ist, ist nur vermutet.
3. **Orientierung von `emboss_text`.** Angenommen: Glyphen in der XY-Ebene, extrudiert
   nach +Z.
4. **Welche Settings-Keys sind pro Volume/Objekt gültig?** `set_param` gibt einen
   Bool zurück, unbekannte Keys scheitern also still. Retraction-Keys sind vermutlich
   **nicht** überschreibbar (siehe unten).
5. Wohin schreibt `print()`, und wie debuggt man sinnvoll?
6. Exakte Pfade von `datadir`/`configdir` unter Windows, macOS und Linux.

## Warum es keinen Retraction Tower gibt

Ursprünglich als erstes Plugin geplant, dann verworfen. Retraction ist in PrusaSlicer
eine **Drucker**-Einstellung (Printer Settings → Extruder), kein Print-Setting, das sich
pro Objekt oder Volume überschreiben lässt. Der Modifier-Weg — wie ihn Flow und Speed
Tower nutzen — greift hier also nicht.

Der G-Code-Weg greift ebenfalls nicht: `M207` steuert nur die *Firmware*-Retraction,
während PrusaSlicer standardmäßig eigene `G1 E`-Züge erzeugt, die von `M207` unberührt
bleiben. Ein Turm, der `M207` schaltet, würde schlicht nichts messen.

Machbar wäre eine Variante, die zusätzlich `use_firmware_retraction` aktiviert. Die misst
dann aber Firmware-Retraction, deren Ergebnis sich nicht auf die normalen
Slicer-Einstellungen übertragen lässt — also ein Plugin, das plausibel aussieht und in die
Irre führt. Bewusst nicht gebaut. Neu bewerten, sobald Retraction-Keys pro Objekt
überschreibbar sind.
