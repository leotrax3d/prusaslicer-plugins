# Developer notes — PrusaSlicer 3.0 plugin system

Everything this project has established about the plugin system, so it does not have to be
worked out again. Reconstructed for **3.0.0-alpha11**; the API is experimental and Prusa
has said breaking changes are expected.

Each claim below is either quoted from PrusaSlicer's source, or marked as an untested
assumption. Where a section says "verified", it means verified against the source or a
running slicer — not guessed from documentation.

## Where the truth lives

The prose documentation is thin and in places wrong. The source is the reference:

| File | What it settles |
| --- | --- |
| `src/slic3r-shared/src/Slic3r/App/Lua/ProjectApi.cpp` | **The API reference.** Registration carries full LuaLS annotations |
| `.../Lua/PluginDialog.cpp` | Which parameter types the dialog accepts |
| `.../Lua/PluginBundle.cpp` / `.hpp` | Manifest fields, bundle detection, plugin loading, signature check |
| `.../Lua/PluginRegistry.cpp` | Scanning vs installing, and what each verifies |
| `.../Lua/AuthorRegistry.cpp` | Where trusted author keys are read from |
| `.../Lua/PluginCliOps.cpp` | `plugin init` / `keygen` / `sign`, and how the ZIP is built |
| `.../App/Plater/PlaterRenderModule.cpp` | Which directories are scanned |
| `resources/lua/com.prusa3d.slicer.calibration/` | Prusa's own plugins, as worked examples |
| `doc/Plugin_API.md` | Getting started; incomplete, see corrections below |

The published reference at <https://prusa.io/ps-plugins/> was unreachable from this
project's environment, so nothing here depends on it.

## Plugin anatomy

A plugin is one `.lua` file exposing a global `info` table and a global `execute(opts)`
function. Menu entries are built from `info.menu` at startup.

```lua
info = {
    id = "fan_tower",                      -- unique within the bundle
    type = "project.plugin",               -- the only type that exists
    title = "Fan Tower",
    menu = "Calibration/Fan Tower",        -- submenu path
    params = {
        {name = "steps", label = "Num Steps", type = "int", default = 5}
    }
}

function execute(opts)
    -- opts.steps holds what the user entered
end
```

### Parameter types — verified

Exactly four, per `PluginDialog.cpp`: `string`, `float`, `int`, `bool`.

No enums, no lists, no min/max bounds, no tooltips, no conditional fields.

> **Correction.** `doc/Plugin_API.md` lists only `float`, `int` and `bool`. `string` does
> exist and Prusa's own Flow Tower uses it. This project initially documented the wrong
> set.

## The two Lua environments — verified, and the subtlest trap here

`PluginBundle::load_plugins()` runs **every** `.lua` file in the bundle through a bare
`Biz::Lua::LuaEngine`, purely to read its `info` table. That engine has **neither `api`
nor the slicer's custom `require`**. Both are registered only on the engine that runs a
plugin after its menu entry is clicked.

```lua
-- WRONG — executes during the scan, aborts the file, no menu entry ever appears
local labels = require('labels')

function execute(opts) ... end
```

```lua
-- RIGHT — runs only on invocation
function execute(opts)
    local labels = require('labels')
    ...
end
```

The failure is silent: the bundle looks as though it were not installed. Prusa's
`flow_tower.lua` requires `note_badge` inside `execute()` for exactly this reason.

`tools/check-plugins.sh` reproduces the scan pass and fails the build on a regression.
Run it before pushing.

## API surface — verified from `ProjectApi.cpp`

### Geometry

All primitives are procedural, so bundled STLs are optional:

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

`Mesh:bounds()` returns `min_x/max_x/min_y/max_y/min_z/max_z`.
`Mesh:translate(x, y, z)` offsets a mesh.

### Objects and volumes

```lua
api.project:add_object{
    mesh = <Mesh>,
    translate = {x =, y =, z =},   -- optional
    rotate = {x =, y =, z =},      -- degrees, optional
    object_params = {...},         -- settings for the whole object
    other_volumes = { <VolumeDefinition>, ... }
}
```

A `VolumeDefinition` has `mesh` plus optional `translate`, `rotate`, `type`, `params`.
`VolumeType`: `Solid`, `Negative`, `Modifier`, `SupportBlocker`, `SupportEnforcer`,
`Invalid`. Supplying `params` without `type` implies `Modifier`.

Negative volumes give boolean subtraction; modifier volumes give position-dependent
settings. `add_object` may be called more than once to place separate objects.

### Settings

```lua
local bed = api.project:current_bed()
bed:print_presets():set(name, value)   -- and :value(name)
bed:printer_presets()
bed:tool_print_presets(tool_idx)
bed:material_presets(slot_idx)
bed:printer_config().tools[1]:nozzle_diameter()
```

`set_param` returns a boolean and **unknown keys fail silently** — a typo in a setting
name produces no error, just no effect.

### Per-layer custom G-code

```lua
api.project:insert_layer_custom_gcode(bed, z_depth, gcode)
api.project:clear_layer_custom_steps(bed)
```

This is the lever for anything that is *firmware state* — temperature (`M104`), fan
(`M106`/`M107`). It **inserts** a snippet; it cannot replace or suppress the slicer's own
extrusion moves.

## Bundles

A bundle is a flat directory of `.lua` files plus `manifest.json`. Subdirectories are not
supported and file names are restricted to `[a-zA-Z0-9.-_ ]+`.

Required manifest fields: `id` (reverse-DNS), `name`, `version`, `author`, `license`,
`min_slicer_version`, `required_apis`.
Optional: `description`, `category`, `web`, `repo`, `max_slicer_version`.

`min_slicer_version` is parsed but **not enforced** at scan time — a bundle is not
rejected for declaring a newer version than the running build.

`PluginBundle::is_plugin_bundle_dir()` checks one thing: that `manifest.json` exists in
the directory.

Scaffold a new bundle with `<install path>/PrusaSlicer plugin init com.example.my-plugin`.

## Installation — two routes, very different rules

Scanned at startup (`PlaterRenderModule.cpp`): `resources_dir()/lua` and `data_dir()/lua`.

| | Copy directory into `(data dir)/lua` | Import a ZIP |
| --- | --- | --- |
| Code path | `PluginRegistry::scan()` | `PluginRegistry::install()` |
| Signature required | **No** — verifies nothing | **Yes** |
| Author public key required | No | **Yes** |

ZIP import loads `(data dir)/authorized_authors/<author>.pem`, where `<author>` is the
manifest's `author` field, then verifies `manifest.sign` against it. A missing key gives
`Cannot load public key for author <name>`; a bad signature gives
`Integrity verification failed`.

> **Correction.** This project initially documented signing as optional, having read
> `PluginSystem::install()` without following into `PluginRegistry::install()` where the
> check actually lives.

Signing therefore gates the *convenient install path*, not execution. What constrains a
plugin dropped into `lua` is the sandbox.

### ZIP layout

The archive must hold the bundle's files **at its root**, not the bundle directory.
`load_meta()` reads the entry named exactly `manifest.json`; zipping the folder makes it
`<bundle-id>/manifest.json` and the install fails with `cannot load manifest.json`. This
matches how `plugin sign` builds archives — files are added under paths relative to the
bundle directory.

A signed bundle additionally carries `manifest.txt` (a SHA-256 per file, formatted
`<hex>  <name>` per line) and `manifest.sign` (an RSA signature over that listing).

```bash
<install path>/PrusaSlicer plugin keygen -P author.private.pem -p author.public.pem
<install path>/PrusaSlicer plugin sign   -P author.private.pem com.example.my-plugin
```

### Data directory name

`<app dir>` follows the application key the build was compiled with. The 3.0 alphas do
**not** use the plain name — a 3.0.0-alpha11 Windows install was observed using
`PrusaSlicer3-dev` (`%APPDATA%\PrusaSlicer3-dev\lua`). Stable releases use `PrusaSlicer`.
`--datadir` overrides everything.

Do not guess: the data directory is the folder holding `PrusaSlicer.ini` and the saved
presets.

## Sandbox

No `os`, no `io`, no network, no process execution. File access is limited to the
plugin's own directory. `print()` exists — where its output goes is unverified.

## What the system cannot do

Worth knowing before designing anything, because these recur:

- **No G-code post-processing.** Plugins never see the toolpath or the sliced output.
- **No events.** A plugin runs only when its menu entry is clicked. There is no
  post-slice hook.
- **No persistence.** No sanctioned place for plugin state to survive a restart; writing
  into a signed bundle would break its signature.
- **No network**, no access to arbitrary files.
- **No viewport gizmos**, and no dialog controls beyond the four parameter types.

### Ideas ruled out, and why

**Filament database** — needs persistence, a post-slice hook to deduct material, and
ideally network sync. Three independent blockers, and `project.plugin` is the wrong
category besides. Revisit if a key-value store and a post-slice hook appear.

**Arc overhangs** — a toolpath algorithm: it must replace the slicer's generated path in
overhang regions. Plugins run before slicing and never see the toolpath;
`insert_layer_custom_gcode` inserts but cannot suppress. Exists in practice as a Python
post-processing script. Would need a toolpath plugin type.

**Retraction tower** — retraction is a *printer* setting, not an object-overridable print
setting, so the modifier-volume approach used by Flow and Speed Towers does not reach it.
`M207` only affects firmware retraction, while PrusaSlicer emits its own `G1 E` moves, so
the G-code route measures nothing. A variant enabling `use_firmware_retraction` would
measure something that does not transfer to normal settings — misleading, so deliberately
not built.

Post-processing scripts remain the escape hatch for all of the above: any language, full
system rights, no sandbox, configured under Print Settings → Post-processing scripts.

## Unverified assumptions

Everything in this project's plugins that could not be settled from the source. All three
concern text engraving and are isolated in `labels.lua`, so one fix corrects every plugin.

1. **Rotation pivot.** Is `rotate` applied about the volume's local origin, and before
   `translate`? Prusa's Temperature Tower uses `rotate{x = 90}` with hand-tuned constants
   from which the semantics cannot be safely inferred.
2. **Primitive origins.** `its_make_cube` builds from (0,0,0), consistent with
   `note_badge.lua`. Whether `make_cylinder` is centred in XY is inferred, not confirmed.
3. **`emboss_text` orientation.** Assumed glyphs in the XY plane, extruded along +Z.

Also open: where `print()` writes, and what a workable debugging loop looks like.

## Working on this repository

```bash
luac -p plugins/*/*.lua      # syntax
./tools/check-plugins.sh     # simulates the slicer's scan pass
```

Both run in CI before a release is published, along with a check that each built archive
is flat and carries a root `manifest.json`.

There is no way to unit-test plugin behaviour: `api`, `VolumeType` and the preset system
exist only inside PrusaSlicer. Everything beyond loading has to be exercised by hand.

Releases are cut by the `Release` workflow, on a `v*` tag or via `workflow_dispatch` with
a version input. Note that tag pushes fail from the Claude Code remote environment (the
git proxy rejects tag refs), which is why the manual trigger exists.
