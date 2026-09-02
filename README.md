# prusaslicer-plugins (unofficial)

Lua plugins for [PrusaSlicer 3.0](https://github.com/prusa3d/PrusaSlicer), which introduced
the slicer's first official plugin system.

## Status

PrusaSlicer 3.0 is in early alpha and Prusa has marked the Lua API as experimental, with
breaking changes expected. Everything here targets `3.0.0-alpha11`.

The plugins in this repository pass syntax checks but **have not been run against a live
slicer**. Treat them as drafts, and see [Testing](#testing) for what that means in practice.

## Plugins

### `com.leotrax3d.calibration` — Calibration Extras

Fills the gaps around the Flow Tower and Temperature Tower that ship with PrusaSlicer.

| Plugin | Menu | Purpose |
| --- | --- | --- |
| Fan Tower | Calibration/Fan Tower | Steps part cooling per height band via `M106`. A thin pillar beside the tower forces a travel move every layer, so it barely cools between passes and reveals insufficient cooling first. |
| Speed Tower | Calibration/Speed Tower | Steps print speed per height band using modifier volumes. |
| Tolerance Test | Calibration/Tolerance Test | A plate of holes with increasing clearance plus a matching test pin, to find the fit allowance your printer and filament actually need. |

A retraction tower was planned and deliberately dropped — retraction is a printer setting
rather than an object-overridable print setting, so neither the modifier nor the G-code
route measures anything meaningful. The reasoning is in
[`docs/api-notes.md`](docs/api-notes.md#why-there-is-no-retraction-tower).

## Installation

Copy a bundle from `plugins/` into the slicer's `lua` directory and restart. Full
per-platform paths and troubleshooting are in
[`docs/installation.md`](docs/installation.md).

Prusa is building a plugin marketplace with one-click installs and signature checking.
Until it ships, manual installation is the only route.

## Documentation

| Document | Contents |
| --- | --- |
| [`docs/installation.md`](docs/installation.md) | Per-platform install paths, updating, uninstalling |
| [`docs/api-notes.md`](docs/api-notes.md) | Reconstructed API reference and unresolved questions |
| [`docs/roadmap.md`](docs/roadmap.md) | Planned phases and what is currently blocked |

## The plugin API in brief

The full reference with signatures is in [`docs/api-notes.md`](docs/api-notes.md).

A plugin is a Lua file exposing a global `info` table and a global `execute(opts)`
function. PrusaSlicer scans its `lua` directory at startup, builds menu entries from each
plugin's `menu` field, generates a parameter dialog from `info.params`, and calls
`execute` with the values the user entered.

**Available:** eleven procedural mesh primitives (`make_cube`, `make_cylinder`,
`make_torus`, `make_snap`, and more), plus `load_stl`, `emboss_svg` and `emboss_text`;
negative and modifier volumes, along with support blockers and enforcers; per-object and
per-volume setting overrides; read and write access to print, printer and material
presets; and custom G-code injected at a given Z height.

**Not available:** G-code post-processing, network access, filesystem access outside the
plugin's own directory, persistence across restarts, event hooks (a plugin runs only when
its menu entry is clicked), custom 3D viewport gizmos, and any dialog control beyond the
four parameter types `string`, `float`, `int` and `bool`.

These limits are what shape the [roadmap](docs/roadmap.md) — most notably they are why a
filament database is not currently buildable.

### Minimal plugin

```lua
info = {
    id = "hello",
    type = "project.plugin",
    title = "Hello world",
    menu = "Tutorial/Hello world",
    params = {
        {name = "text", label = "Text", type = "string", default = "Hello world"}
    }
}

function execute(opts)
    api.project:add_object{
        mesh = api.emboss_text{
            font = api.get_default_font(),
            text = opts.text,
            depth = 1
        },
        object_params = {fill_density = "0%"}
    }
end
```

## Repository layout

```
plugins/<bundle-id>/   plugin bundle: manifest.json plus Lua scripts
docs/                  installation, API notes, roadmap
```

Bundles use reverse-DNS identifiers. A bundle groups related plugins under one
`manifest.json`; each `.lua` file in it that defines `info` becomes its own menu entry.
Files that return a module instead — `labels.lua`, for example — are shared helpers loaded
with `require('labels')`.

## Development

Scaffold a new bundle with the slicer's built-in wizard:

```bash
<installation_path>/PrusaSlicer plugin init com.example.my-plugin
```

Bundles are distributed as ZIP archives signed with an RSA key pair:

```bash
# once, to create a key pair
<installation_path>/PrusaSlicer plugin keygen -P author.private.pem -p author.public.pem

# for each release
<installation_path>/PrusaSlicer plugin sign -P author.private.pem com.example.my-plugin
```

Private keys must never be committed to this repository.

### Testing

```bash
luac -p plugins/*/*.lua
```

Syntax checking is the only automated verification available. The slicer's Lua environment
— `api`, `VolumeType`, the preset system — does not exist outside PrusaSlicer, so there is
no way to unit-test plugin behaviour on its own. Every plugin has to be exercised by hand
in the slicer.

Because of that, geometry assumptions that could not be settled from the source are
isolated in one place: `labels.lua` holds all text-engraving placement, so if the rotation
or emboss semantics turn out differently, a single file needs correcting rather than every
plugin. The open questions are tracked in [`docs/api-notes.md`](docs/api-notes.md).

## Contributing

Issues and pull requests are welcome. Since the API is still moving, always state which
alpha version you tested against, and note whether a change is verified in the slicer or
inferred from the source.

## License

MIT. See [LICENSE](LICENSE).

The plugins are original work written against PrusaSlicer's public Lua API. They contain
no PrusaSlicer source code, so the slicer's AGPL licensing does not extend to them.

## Trademarks

"Prusa", "PrusaSlicer" and "Original Prusa" are trademarks of Prusa Research s.r.o. This
is an independent, unofficial project. It is not affiliated with, endorsed by, or
supported by Prusa Research, and the name is used only to identify the software these
plugins are written for. For support with PrusaSlicer itself, contact Prusa Research; for
problems with these plugins, open an issue here.

## References

- [`doc/Plugin_API.md`](https://github.com/prusa3d/PrusaSlicer/blob/version_3.0.0-alpha11/doc/Plugin_API.md) — official plugin documentation
- [`ProjectApi.cpp`](https://github.com/prusa3d/PrusaSlicer/blob/version_3.0.0-alpha11/src/slic3r-shared/src/Slic3r/App/Lua/ProjectApi.cpp) — the API registration, annotated; the most complete reference available
- [PrusaSlicer 3.0.0-alpha11 release notes](https://github.com/prusa3d/PrusaSlicer/releases/tag/version_3.0.0-alpha11)
- [Plugin API reference](https://prusa.io/ps-plugins/)
