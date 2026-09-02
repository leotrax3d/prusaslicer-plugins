# Lua API notes

Reconstructed for PrusaSlicer **3.0.0-alpha11**. The API is experimental and breaking
changes are expected.

The prose documentation is thin, so the useful sources are the source files themselves:

- [`doc/Plugin_API.md`](https://github.com/prusa3d/PrusaSlicer/blob/version_3.0.0-alpha11/doc/Plugin_API.md) — getting started, manifest, signing
- [`ProjectApi.cpp`](https://github.com/prusa3d/PrusaSlicer/blob/version_3.0.0-alpha11/src/slic3r-shared/src/Slic3r/App/Lua/ProjectApi.cpp) — **the real reference**; the registration carries complete LuaLS annotations
- [`PluginDialog.cpp`](https://github.com/prusa3d/PrusaSlicer/blob/version_3.0.0-alpha11/src/slic3r-shared/src/Slic3r/App/Lua/PluginDialog.cpp) — which parameter types the dialog accepts
- `resources/lua/com.prusa3d.slicer.calibration/` — Prusa's own plugins, as reference implementations

## Plugin skeleton

A global `info` table and a global `execute(opts)` function. Other Lua files in the bundle
can be loaded as modules with `require('filename')`, without the extension.

## Parameter types

Exactly four, per `PluginDialog.cpp`: `string`, `float`, `int`, `bool`. No enums, no
lists, no min/max bounds, no tooltips.

> `doc/Plugin_API.md` lists only `float`, `int` and `bool`. `string` does exist and is used
> by Prusa's own Flow Tower.

## Geometry

All primitives are procedural, so bundled STLs are not required:

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
api.emboss_text{font =, text =, depth =, line_height =}

api.fonts() / api.get_default_font() / api.get_font(name)
```

`Mesh:bounds()` returns a bounding box with `min_x/max_x/min_y/max_y/min_z/max_z`;
`Mesh:translate(x, y, z)` offsets the mesh.

## Objects and volumes

```lua
api.project:add_object{
    mesh = <Mesh>,
    translate = {x =, y =, z =},   -- optional
    rotate = {x =, y =, z =},      -- degrees, optional
    object_params = {...},         -- settings for the whole object
    other_volumes = { <VolumeDefinition>, ... }
}
```

A `VolumeDefinition` has `mesh` plus optional `translate`, `rotate`, `type` and `params`.
`VolumeType` values: `Solid`, `Negative`, `Modifier`, `SupportBlocker`, `SupportEnforcer`,
`Invalid`. Omitting `type` while supplying `params` implies `Modifier`.

Negative volumes give boolean subtraction and modifier volumes give position-dependent
settings — substantially more than the prose documentation implies.

## Settings

```lua
local bed = api.project:current_bed()
bed:print_presets():set(name, value)   -- and :value(name)
bed:printer_presets()
bed:tool_print_presets(tool_idx)
bed:material_presets(slot_idx)
bed:printer_config().tools[1]:nozzle_diameter()
```

## Per-layer custom G-code

```lua
api.project:insert_layer_custom_gcode(bed, z_depth, gcode)
api.project:clear_layer_custom_steps(bed)
```

This is the lever for anything that is **firmware state**: temperature (`M104`), fan
(`M106`/`M107`). Prusa's Temperature Tower works exactly this way.

## Sandbox

No `os`, no `io`, no network. File access is limited to the plugin's own directory.
`print()` exists — the Flow Tower uses it — but where the output goes is unverified.

## Open questions

These could not be settled from the source and need verification against a running
slicer. Everything below is an assumption the plugins in this repository currently rely
on.

1. **Rotation pivot.** Is `rotate` applied about the volume's local origin, and before
   `translate`? `labels.lua` assumes both. Prusa's Temperature Tower does use
   `rotate{x = 90}`, but with hand-tuned constants from which the semantics cannot be
   safely inferred.
2. **Primitive origins.** `its_make_cube` builds a cube from (0,0,0), consistent with
   `note_badge.lua`. Whether `make_cylinder` is centred in XY is only inferred.
3. **`emboss_text` orientation.** Assumed to place glyphs in the XY plane, extruded
   along +Z.
4. **Which setting keys are valid per volume or object?** `set_param` returns a boolean,
   so unknown keys fail silently. Retraction keys are probably not overridable — see
   below.
5. Where does `print()` write, and what is a workable debugging loop?

## Why there is no retraction tower

Originally planned as the first plugin, then dropped.

Retraction in PrusaSlicer is a **printer** setting (Printer Settings → Extruder), not a
print setting that can be overridden per object or per volume. The modifier-volume
approach used by the Flow and Speed Towers therefore does not reach it.

The G-code route does not work either. `M207` configures *firmware* retraction, whereas
PrusaSlicer emits its own `G1 E` moves by default, which `M207` does not affect. A tower
that stepped `M207` would measure nothing.

A variant that also enables `use_firmware_retraction` would be technically possible, but
it would measure firmware retraction, whose results do not transfer to the normal slicer
retraction settings — a plugin that looks plausible and misleads. Deliberately not built.
Worth revisiting if retraction keys become overridable per object.
